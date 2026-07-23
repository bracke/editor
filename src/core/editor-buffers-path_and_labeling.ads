with Editor.Project;

package Editor.Buffers.Path_And_Labeling is

   function Metadata_Label_Max_Length return Positive;

   function Bounded_Metadata_Label (Value : String) return String;

   function Pure_Normalize_Path (Path : String) return String;

   function Pure_Same_Or_Descendant_Path
     (Path : String;
      Root : String) return Boolean;

   function Pure_Relative_Path
     (Path : String;
      Root : String) return String;

   function Classify_Buffer_Ownership
     (Has_Path : Boolean;
      Path     : String;
      Project  : Editor.Project.Project_State) return Buffer_Ownership_Kind;

   function Ownership_Label (Kind : Buffer_Ownership_Kind) return String;

   function Dirty_Category_Label (Kind : Buffer_Dirty_Category) return String;

   function Close_Eligibility_Label (Kind : Buffer_Close_Eligibility) return String;

   function Workspace_Persistability_Label
     (Kind : Buffer_Workspace_Persistability) return String;

   function Lifecycle_Status_Label_For
     (File : File_Identity) return String;

end Editor.Buffers.Path_And_Labeling;
