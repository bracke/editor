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

end Editor.Buffer_Switcher.Filters;
