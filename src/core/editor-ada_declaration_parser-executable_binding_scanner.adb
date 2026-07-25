with Editor.Ada_Declaration_Parser.Executable_Binding_Scanner.Text_Scan;
with Editor.Ada_Language_Model;

package body Editor.Ada_Declaration_Parser.Executable_Binding_Scanner is

   procedure Add_Executable_Bindings_From_Text
     (Analysis : in out Editor.Ada_Language_Model.Analysis_Result;
      Text     : String)
   is
      package Scanner is new
        Editor.Ada_Declaration_Parser.Executable_Binding_Scanner.Text_Scan
          (Analysis);
   begin
      Scanner.Scan_Text (Text);
   end Add_Executable_Bindings_From_Text;

end Editor.Ada_Declaration_Parser.Executable_Binding_Scanner;
