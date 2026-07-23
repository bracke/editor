with Editor.Ada_Declaration_Parser.Semantic_Phases_Layers;
with Editor.Ada_Language_Model;

package body Editor.Ada_Declaration_Parser.Semantic_Phases_Engine is

   function Parse
     (Text         : String;
      Buffer_Label : String := "") return Editor.Ada_Language_Model.Analysis_Result
   is
   begin
      return Editor.Ada_Declaration_Parser.Semantic_Phases_Layers.Parse
        (Text         => Text,
         Buffer_Label => Buffer_Label);
   end Parse;

end Editor.Ada_Declaration_Parser.Semantic_Phases_Engine;
