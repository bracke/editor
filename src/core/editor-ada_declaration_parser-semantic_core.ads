with Editor.Ada_Language_Model;

package Editor.Ada_Declaration_Parser.Semantic_Core is

   function Parse
     (Text         : String;
      Buffer_Label : String := "") return Editor.Ada_Language_Model.Analysis_Result;

end Editor.Ada_Declaration_Parser.Semantic_Core;
