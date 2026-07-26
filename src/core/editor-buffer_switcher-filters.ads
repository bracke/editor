with Ada.Strings.Unbounded;

package Editor.Buffer_Switcher.Filters is

   subtype Switcher_Metadata_Filter_Kind is Editor.Buffer_Switcher.Switcher_Metadata_Filter_Kind;
   subtype Switcher_Metadata_Filter is Editor.Buffer_Switcher.Switcher_Metadata_Filter;
   subtype Switcher_Sort_Mode is Editor.Buffer_Switcher.Switcher_Sort_Mode;

   No_Filter : constant Switcher_Metadata_Filter_Kind := Editor.Buffer_Switcher.No_Filter;
   Pinned_Filter : constant Switcher_Metadata_Filter_Kind := Editor.Buffer_Switcher.Pinned_Filter;
   Group_Filter : constant Switcher_Metadata_Filter_Kind := Editor.Buffer_Switcher.Group_Filter;
   Label_Filter : constant Switcher_Metadata_Filter_Kind := Editor.Buffer_Switcher.Label_Filter;
   Noted_Filter : constant Switcher_Metadata_Filter_Kind := Editor.Buffer_Switcher.Noted_Filter;
   Dirty_Filter : constant Switcher_Metadata_Filter_Kind := Editor.Buffer_Switcher.Dirty_Filter;
   Clean_Filter : constant Switcher_Metadata_Filter_Kind := Editor.Buffer_Switcher.Clean_Filter;
   Missing_Or_Conflict_Filter : constant Switcher_Metadata_Filter_Kind := Editor.Buffer_Switcher.Missing_Or_Conflict_Filter;
   Project_Owned_Filter : constant Switcher_Metadata_Filter_Kind := Editor.Buffer_Switcher.Project_Owned_Filter;
   Outside_Project_Filter : constant Switcher_Metadata_Filter_Kind := Editor.Buffer_Switcher.Outside_Project_Filter;
   Scratch_Filter : constant Switcher_Metadata_Filter_Kind := Editor.Buffer_Switcher.Scratch_Filter;

   Default_Sort : constant Switcher_Sort_Mode := Editor.Buffer_Switcher.Default_Sort;
   Recent_Sort : constant Switcher_Sort_Mode := Editor.Buffer_Switcher.Recent_Sort;
   Name_Sort : constant Switcher_Sort_Mode := Editor.Buffer_Switcher.Name_Sort;
   Pinned_Sort : constant Switcher_Sort_Mode := Editor.Buffer_Switcher.Pinned_Sort;
   Group_Sort : constant Switcher_Sort_Mode := Editor.Buffer_Switcher.Group_Sort;
   Label_Sort : constant Switcher_Sort_Mode := Editor.Buffer_Switcher.Label_Sort;

end Editor.Buffer_Switcher.Filters;
