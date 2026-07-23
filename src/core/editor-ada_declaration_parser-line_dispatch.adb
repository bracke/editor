with Editor.Ada_Declaration_Parser.Lexical_Helpers;

package body Editor.Ada_Declaration_Parser.Line_Dispatch is

   function Starts_With_Declaration_Or_Metadata
     (Decl_Lower : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Lexical_Helpers
       .Is_Declaration_Or_Metadata_Line;

end Editor.Ada_Declaration_Parser.Line_Dispatch;
