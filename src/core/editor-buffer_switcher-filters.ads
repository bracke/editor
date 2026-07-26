with Editor.Buffer_Switcher_Model.Filters;

package Editor.Buffer_Switcher.Filters is

   subtype Switcher_Metadata_Filter_Kind is
     Editor.Buffer_Switcher_Model.Filters.Switcher_Metadata_Filter_Kind;
   subtype Switcher_Metadata_Filter is
     Editor.Buffer_Switcher_Model.Filters.Switcher_Metadata_Filter;
   subtype Switcher_Sort_Mode is
     Editor.Buffer_Switcher_Model.Filters.Switcher_Sort_Mode;

   No_Filter : constant Switcher_Metadata_Filter_Kind := Editor.Buffer_Switcher_Model.Filters.No_Filter;
   Pinned_Filter : constant Switcher_Metadata_Filter_Kind := Editor.Buffer_Switcher_Model.Filters.Pinned_Filter;
   Group_Filter : constant Switcher_Metadata_Filter_Kind := Editor.Buffer_Switcher_Model.Filters.Group_Filter;
   Label_Filter : constant Switcher_Metadata_Filter_Kind := Editor.Buffer_Switcher_Model.Filters.Label_Filter;
   Noted_Filter : constant Switcher_Metadata_Filter_Kind := Editor.Buffer_Switcher_Model.Filters.Noted_Filter;
   Dirty_Filter : constant Switcher_Metadata_Filter_Kind := Editor.Buffer_Switcher_Model.Filters.Dirty_Filter;
   Clean_Filter : constant Switcher_Metadata_Filter_Kind := Editor.Buffer_Switcher_Model.Filters.Clean_Filter;
   Missing_Or_Conflict_Filter : constant Switcher_Metadata_Filter_Kind := Editor.Buffer_Switcher_Model.Filters.Missing_Or_Conflict_Filter;
   Project_Owned_Filter : constant Switcher_Metadata_Filter_Kind := Editor.Buffer_Switcher_Model.Filters.Project_Owned_Filter;
   Outside_Project_Filter : constant Switcher_Metadata_Filter_Kind := Editor.Buffer_Switcher_Model.Filters.Outside_Project_Filter;
   Scratch_Filter : constant Switcher_Metadata_Filter_Kind := Editor.Buffer_Switcher_Model.Filters.Scratch_Filter;

   Default_Sort : constant Switcher_Sort_Mode := Editor.Buffer_Switcher_Model.Filters.Default_Sort;
   Recent_Sort : constant Switcher_Sort_Mode := Editor.Buffer_Switcher_Model.Filters.Recent_Sort;
   Name_Sort : constant Switcher_Sort_Mode := Editor.Buffer_Switcher_Model.Filters.Name_Sort;
   Pinned_Sort : constant Switcher_Sort_Mode := Editor.Buffer_Switcher_Model.Filters.Pinned_Sort;
   Group_Sort : constant Switcher_Sort_Mode := Editor.Buffer_Switcher_Model.Filters.Group_Sort;
   Label_Sort : constant Switcher_Sort_Mode := Editor.Buffer_Switcher_Model.Filters.Label_Sort;

   procedure Clear_Metadata_Filter
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);
   procedure Set_Pinned_Filter
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);
   procedure Set_Group_Filter
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Name  : String);
   procedure Set_Label_Filter
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Label : String);
   procedure Set_Noted_Filter
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);
   procedure Set_Dirty_Filter
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);
   procedure Set_Clean_Filter
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);
   procedure Set_Missing_Or_Conflict_Filter
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);
   procedure Set_Project_Owned_Filter
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);
   procedure Set_Outside_Project_Filter
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);
   procedure Set_Scratch_Filter
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);
   function Has_Metadata_Filter
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean;
   function Metadata_Filter
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State)
      return Switcher_Metadata_Filter;
   function Metadata_Filter_Description
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return String;

   procedure Set_Sort_Mode
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Mode  : Switcher_Sort_Mode);
   procedure Clear_Sort_Mode
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);
   procedure Next_Sort_Mode
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);
   procedure Previous_Sort_Mode
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);
   function Sort_Mode
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State)
      return Switcher_Sort_Mode;
   function Sort_Mode_Description
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return String;

end Editor.Buffer_Switcher.Filters;
