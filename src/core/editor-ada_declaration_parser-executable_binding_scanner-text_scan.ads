with Editor.Ada_Language_Model;

generic
   Analysis : in out Editor.Ada_Language_Model.Analysis_Result;
package Editor.Ada_Declaration_Parser.Executable_Binding_Scanner.Text_Scan is

   procedure Scan_Text (Text : String);

end Editor.Ada_Declaration_Parser.Executable_Binding_Scanner.Text_Scan;
