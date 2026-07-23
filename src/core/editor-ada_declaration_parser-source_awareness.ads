with Editor.Ada_Language_Model;

package Editor.Ada_Declaration_Parser.Source_Awareness is

   function Is_Invalid_Compact_Owner_Name (Name : String) return Boolean;

   procedure Mark_Context_Clause_Awareness
     (Analysis    : in out Editor.Ada_Language_Model.Analysis_Result;
      Line        : String;
      Line_Number : Positive;
      Scope       : Editor.Ada_Language_Model.Scope_Id);

   procedure Mark_Source_Awareness
     (Analysis : in out Editor.Ada_Language_Model.Analysis_Result;
      Line     : String);

end Editor.Ada_Declaration_Parser.Source_Awareness;
