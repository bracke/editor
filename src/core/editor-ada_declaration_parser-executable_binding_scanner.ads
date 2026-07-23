with Editor.Ada_Language_Model;

package Editor.Ada_Declaration_Parser.Executable_Binding_Scanner is

   procedure Add_Executable_Bindings_From_Text
     (Analysis : in out Editor.Ada_Language_Model.Analysis_Result;
      Text     : String);

end Editor.Ada_Declaration_Parser.Executable_Binding_Scanner;
