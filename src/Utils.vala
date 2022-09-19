/*
* Copyright (c) 2011-2020 elementary, Inc. (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License version 3, as published by the Free Software Foundation.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU Lesser General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/


namespace Terminal.Utils {
    public string? sanitize_path (string _path, string shell_location) {
        /* Remove trailing whitespace, ensure scheme, substitute leading "~" and "..", remove extraneous "/" */
        string scheme, path;

        var parts_scheme = _path.split ("://", 2);
        if (parts_scheme.length == 2) {
            scheme = parts_scheme[0] + "://";
            path = parts_scheme[1];
        } else {
            scheme = "file://";
            path = _path;
        }

        path = Uri.unescape_string (path);
        if (path == null) {
            return null;
        }

        path = strip_uri (path);

        do {
            path = path.replace ("//", "/");

        } while (path.contains ("//"));

        var parts_sep = path.split (Path.DIR_SEPARATOR_S, 3);
        var index = 0;
        while (parts_sep[index] == null && index < parts_sep.length - 1) {
            index++;
        }

        if (parts_sep[index] == "~") {
            parts_sep[index] = Environment.get_home_dir ();
        } else if (parts_sep[index] == ".") {
            parts_sep[index] = shell_location;
        } else if (parts_sep[index] == "..") {
            parts_sep[index] = construct_parent_path (shell_location);
        }

        var result = escape_uri (scheme + string.joinv (Path.DIR_SEPARATOR_S, parts_sep).replace ("//", "/"));
        return result;
    }

    public string? sanitize_uri (string input) {
        string remaining  = input;

        string scheme; 
        var parts_scheme = remaining.split ("://", 2);
        if (parts_scheme.length == 2) {
            scheme = parts_scheme[0];
            remaining = parts_scheme[1];
        } else {
            scheme = "file";
        }

        string? fragment = null;
        var fragment_parts = remaining.split ("#", 2);
        remaining = fragment_parts[0];
        if (fragment_parts.length == 2) {
            fragment = Uri.escape_string(fragment_parts[1], "/");
        }

        string? query = null;
        var query_parts = remaining.split ("?", 2);
        remaining = query_parts[0];
        if (query_parts.length == 2) {
            query = Uri.escape_string(query_parts[1], "&");
        }

        string? username = null, password = null;
        var username_parts = remaining.split("@", 2);
        if (username_parts.length == 2) {
            remaining = username_parts[1];

            var password_parts = username_parts[0].split(":", 2);
            username = Uri.escape_string(password_parts[0]);
            if (password_parts.length == 2) {
                password = Uri.escape_string(password_parts[1]);
            }
        }

        string path = Uri.escape_string(remaining, "/");

        string result = scheme + "://";

        if (username == null) {
            result = result + path;
        } else if (password == null) {
            result = result + username + "@" + path;
        } else {
            result = result + username + ":" + password + "@" + path;
        }

        if (query != null) {
            result = result + "?" + query;
        }

        if (fragment != null) {
            result = result + "#" + fragment;
        }

        return result;
    }

    /*** Simplified version of PF.FileUtils function, with fewer checks ***/
    public string get_parent_path_from_path (string path) {
        if (path.length < 2) {
            return Path.DIR_SEPARATOR_S;
        }

        StringBuilder string_builder = new StringBuilder (path);
        if (path.has_suffix (Path.DIR_SEPARATOR_S)) {
            string_builder.erase (string_builder.str.length - 1, -1);
        }

        int last_separator = string_builder.str.last_index_of (Path.DIR_SEPARATOR_S);
        if (last_separator < 0) {
            last_separator = 0;
        }

        string_builder.erase (last_separator, -1);
        return string_builder.str + Path.DIR_SEPARATOR_S;
    }

    private string construct_parent_path (string path) {
        if (path.length < 2) {
            return Path.DIR_SEPARATOR_S;
        }

        var sb = new StringBuilder (path);

        if (path.has_suffix (Path.DIR_SEPARATOR_S)) {
            sb.erase (sb.str.length - 1, -1);
        }

        int last_separator = sb.str.last_index_of (Path.DIR_SEPARATOR_S);
        if (last_separator < 0) {
            last_separator = 0;
        }
        sb.erase (last_separator, -1);

        string parent_path = sb.str + Path.DIR_SEPARATOR_S;

        return parent_path;
    }

    private string? strip_uri (string? _uri) {
        string uri = _uri;
        /* Strip off any trailing spaces, newlines or carriage returns */
        if (_uri != null) {
            uri = uri.strip ();
            uri = uri.replace ("\n", "");
            uri = uri.replace ("\r", "");
        }

        return uri;
    }

    private string? escape_uri (string uri, bool allow_utf8 = true, bool allow_single_quote = true) {
        string rc = (Uri.RESERVED_CHARS_GENERIC_DELIMITERS +
                     Uri.RESERVED_CHARS_SUBCOMPONENT_DELIMITERS).replace ("#", "").replace ("*", "").replace ("~", "");

        if (!allow_single_quote) {
            rc = rc.replace ("'", "");
        }

        return Uri.escape_string ((Uri.unescape_string (uri) ?? uri), rc , allow_utf8);
    }

}
