with Editor.Workspace_Persistence;
with Ada.Strings.Unbounded;

package Editor.Workspace_Persistence.Path_Validation is

   function Has_Control_Character (Path : String) return Boolean;
   function Has_Workspace_Path_Meta_Character (Path : String) return Boolean;
   function Has_Backslash_Separator (Path : String) return Boolean;
   function Is_Absolute_Path (Path : String) return Boolean;
   function Normalize_Project_Relative_Path
     (Path  : String;
      Valid : out Boolean) return String;

   function Is_Safe_Project_Relative_Path
     (Path : String) return Boolean;

   function Comparable_Path (Path : String) return String;

end Editor.Workspace_Persistence.Path_Validation;
