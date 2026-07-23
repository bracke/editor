with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker;

package body Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers is

   function Parse
     (Text         : String;
      Buffer_Label : String := "") return Editor.Ada_Language_Model.Analysis_Result
   is
   begin
      return
        Editor.Ada_Declaration_Parser.
          Semantic_Phases_Engine_Layers_Projection_Worker.Parse
            (Text         => Text,
             Buffer_Label => Buffer_Label);
   end Parse;

end Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers;
