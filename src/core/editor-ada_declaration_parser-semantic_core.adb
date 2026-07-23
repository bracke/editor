with Editor.Ada_Declaration_Parser.Semantic_Phases;
with Editor.Ada_Language_Model;

package body Editor.Ada_Declaration_Parser.Semantic_Core is

   function Parse
     (Text         : String;
      Buffer_Label : String := "") return Editor.Ada_Language_Model.Analysis_Result
   is
   begin
      return Editor.Ada_Declaration_Parser.Semantic_Phases.Parse
        (Text         => Text,
         Buffer_Label => Buffer_Label);
   end Parse;

end Editor.Ada_Declaration_Parser.Semantic_Core;
