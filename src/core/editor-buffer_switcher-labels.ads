limited with Editor.Buffers;
with Editor.Project;

package Editor.Buffer_Switcher.Labels is

   function Path_Base_Name (Path : String) return String;

   function Parent_Hint (Path : String) return String;

   function Short_Path_Label (Path : String) return String;

   procedure Apply_Buffer_List_Display_Label
     (Row     : in out Buffer_Switcher_Row;
      Project : Editor.Project.Project_State);

   function Metadata_Display_Label
     (Metadata : Editor.Buffers.Buffer_Metadata_Snapshot) return Unbounded_String;

   function Buffer_Row_State_Markers
     (Row : Buffer_Switcher_Row) return String;

   function Buffer_Row_Metadata_Render_Label
     (Row : Buffer_Switcher_Row) return String;

   function Buffer_Project_Ownership_Label
     (Kind : Buffer_Project_Ownership_Kind) return String;

   procedure Apply_Project_Ownership
     (Row     : in out Buffer_Switcher_Row;
      Project : Editor.Project.Project_State);

end Editor.Buffer_Switcher.Labels;
