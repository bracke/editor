with Editor.State;
with Editor.Dirty_Guards;
with Editor.Project;

private package Editor.Buffers.Audits is

   function Project_Lifecycle_Buffer_Sets
     (Registry : Buffer_Registry;
      Project  : Editor.Project.Project_State) return Buffer_Project_Lifecycle_Sets;

   function Audit_Buffers
     (Registry    : Buffer_Registry;
      Project     : Editor.Project.Project_State;
      Selected_Id : Buffer_Id := No_Buffer) return Buffer_Audit_Summary;

   function Buffer_Metadata_Lifecycle_Audit_Coherent
     (Registry    : Buffer_Registry;
      Project     : Editor.Project.Project_State;
      Selected_Id : Buffer_Id := No_Buffer) return Boolean;

   function Project_Owned_Buffer_Count
     (Registry : Buffer_Registry;
      Project  : Editor.Project.Project_State) return Natural;

   function Outside_Project_Buffer_Count
     (Registry : Buffer_Registry;
      Project  : Editor.Project.Project_State) return Natural;

   function Scratch_Buffer_Count
     (Registry : Buffer_Registry) return Natural;

   function Project_Owned_Dirty_Buffer_Count
     (Registry : Buffer_Registry;
      Project  : Editor.Project.Project_State) return Natural;

   function Outside_Project_Dirty_Buffer_Count
     (Registry : Buffer_Registry;
      Project  : Editor.Project.Project_State) return Natural;

   function Scratch_Dirty_Buffer_Count
     (Registry : Buffer_Registry;
      Project  : Editor.Project.Project_State) return Natural;

   function Categorized_Dirty_Buffer_Summary
     (Registry : Buffer_Registry;
      Project  : Editor.Project.Project_State)
      return Editor.Dirty_Guards.Dirty_Buffer_Summary;

   function Project_Lifecycle_Dirty_Buffer_Summary
     (Registry : Buffer_Registry;
      Project  : Editor.Project.Project_State)
      return Editor.Dirty_Guards.Dirty_Buffer_Summary;

   function Unpinned_Clean_Buffer_Count
     (Registry : Buffer_Registry) return Natural;

   function Dirty_Buffer_Count
     (Registry : Buffer_Registry) return Natural;

   function Dirty_File_Backed_Buffer_Count
     (Registry : Buffer_Registry) return Natural;

   function Dirty_Untitled_Buffer_Count
     (Registry : Buffer_Registry) return Natural;

   function Clean_Buffer_Count
     (Registry : Buffer_Registry) return Natural;

   function Dirty_Buffer_Display_Name
     (Registry : Buffer_Registry;
      Index    : Positive) return String;

   function Dirty_Buffer_Summary
     (Registry : Buffer_Registry)
      return Editor.Dirty_Guards.Dirty_Buffer_Summary;

   function Closeable_Unpinned_Clean_Outside_Active_Group_Count
     (Registry : Buffer_Registry) return Natural;

end Editor.Buffers.Audits;
