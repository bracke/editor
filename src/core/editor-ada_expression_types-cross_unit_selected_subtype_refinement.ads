with Editor.Ada_Project_Index;

package Editor.Ada_Expression_Types.Cross_Unit_Selected_Subtype_Refinement is

   function Cross_Unit_Selected_Subtype
     (Index    : Editor.Ada_Project_Index.Index_State;
      Path     : String;
      Selector : String) return String;

end Editor.Ada_Expression_Types.Cross_Unit_Selected_Subtype_Refinement;
