/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * moss.format.source.yml_helper
 *
 * Helper functions for applying and enforcing schemas when parsing
 * YAML format files.
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module moss.format.source.yml_helper;

import dyaml;
import moss.format.source.schema;
import std.exception : enforce;
import std.experimental.logger;
import std.format : format;
import std.stdint;

/**
 * Set value appropriately.
 */
void setValue(T)(ref Node node, ref T value, YamlSchema schema)
{
    import std.algorithm : canFind;

    enforce(node.nodeID == NodeID.scalar, format!"Expected %s for %s"(T.stringof, node.tag));

    static if (is(T == int64_t))
    {
        value = node.as!int64_t;
        debug
        {
            //trace("    '- <int64_t>");
        }
    }
    else static if (is(T == uint64_t))
    {
        value = node.as!uint64_t;
        debug
        {
            //trace("    '- <uint64_t>");
        }
    }
    else static if (is(T == bool))
    {
        value = node.as!bool;
        debug
        {
            //trace("    '- <bool>");
        }
    }
    else
    {
        value = node.as!string;
        debug
        {
            //trace(format!"    '- <string> (= '%s')"(value));
        }
        if (schema.acceptableValues.length < 1)
        {
            return;
        }

        /* Make sure the string is an acceptable value */
        enforce(schema.acceptableValues.canFind(value),
                format!"setValue(): %s not a valid value for %s. Acceptable values: %s"(value,
                    schema.name, schema.acceptableValues));
    }
}

/**
 * Set value according to maps.
 */
void setValueArray(T)(ref Node node, ref T value)
{
    /* We can support a single value *or* a list. */
    enforce(node.nodeID != NodeID.mapping, format!"Expected %s for %s"(T.stringof, node.tag));

    switch (node.nodeID)
    {
        static if (is(T == string) || is(T == string[]))
        {
    case NodeID.scalar:
            value ~= node.as!string;
            debug
            {
                //trace("    '- <string>");
            }
            break;
    case NodeID.sequence:
            debug
            {
                //trace("    '- sequence of <string> scalars:");
            }
            foreach (ref Node v; node)
            {
                value ~= v.as!string;
                debug
                {
                    //trace(format!"     '- '%s'"(v.as!string));
                }
            }
            break;
        }
        else
        {
    case NodeID.scalar:
            value ~= node.as!(typeof(value[0]));
            debug
            {
                //trace(format!"    '- <%s>"(node.as!(typeof(value[0]))));
            }
            break;
    case NodeID.sequence:
            debug
            {
                //trace("    '- sequence of scalars:");
            }
            foreach (ref Node v; node)
            {
                value ~= v.as!(typeof(value[0]));
                debug
                {
                    //trace(format!"     '- '%s' as <%s>"(v, typeof(value[0])));
                }
            }
            break;
        }
    default:
        //trace(format!"    '- node.nodeID %s not parsed?"(node.nodeID));
        break;
    }
}

/**
 * Parse a section in the YAML by the given input node + section, setting as
 * many automatic values as possible using our UDA helper system.
 *
 * This is essentially a dispatch function.
 */
void parseSection(T)(ref Node node, ref T section) @system
{
    import std.traits : getUDAs, hasUDA, moduleName;

    /* Walk the members in the type T section struct -- the order is undefined */
    static foreach (member; __traits(allMembers, T))
    {
        /*
         * The extra set of brackets ensures that each compile time loop
         * gets a clean scope with no duplicate declarations
         * (otherwise the compiler complains vociferously)
         */
        {
            mixin("import " ~ moduleName!T ~ ";");

            /* YamlSchema BEGIN */
            mixin("enum hasYamlSchema = hasUDA!(" ~ T.stringof ~ "." ~ member ~ ", YamlSchema);");
            static if (hasYamlSchema)
            {
                debug
                {
                    /* Add a compile-time message each time a field with a YamlSchema is found */
                    pragma(msg, ">>> YamlSchema found for: ", T, ".", member);
                }

                mixin("enum udaID = getUDAs!(" ~ T.stringof ~ "." ~ member ~ ", YamlSchema);");
                static if (udaID.length == 1)
                {
                    static assert(udaID.length == 1,
                            "Missing YamlSchema for " ~ T.stringof ~ "." ~ member);
                    enum yamlName = udaID[0].name;
                    enum mandatory = udaID[0].required;
                    enum type = udaID[0].type;

                    static if (mandatory)
                    {
                        enforce(node.containsKey(yamlName), "Missing mandatory key: " ~ yamlName);
                    }

                    static if (type == YamlType.Single)
                    {
                        if (node.containsKey(yamlName))
                        {
                            debug
                            {
                                //trace(format!"  '- Parsing YamlSchema for member: %s"(member));
                            }
                            debug
                            {
                                //trace(format!"   '- Parsing YAML key '%s':"(yamlName));
                            }
                            mixin("setValue(node[yamlName], section." ~ member ~ ", udaID);");
                        }
                    }
                    else static if (type == YamlType.Array)
                    {
                        if (node.containsKey(yamlName))
                        {
                            debug
                            {
                                //trace(format!"  '- Parsing YamlSchema for member: %s"(member));
                            }
                            debug
                            {
                                //trace(format!"   '- Parsing YAML key '%s':"(yamlName));
                            }
                            mixin("setValueArray(node[yamlName], section." ~ member ~ ");");
                        }
                    }
                }
            }
            /* YamlSchema END */
        }
    }
}
