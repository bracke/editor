with Ada.Strings.Unbounded;

package Editor.Buffer_Switcher_Model.Filters is

   type Switcher_Metadata_Filter_Kind is
     (No_Filter,
      Pinned_Filter,
      Group_Filter,
      Label_Filter,
      Noted_Filter,
      Dirty_Filter,
      Clean_Filter,
      Missing_Or_Conflict_Filter,
      Project_Owned_Filter,
      Outside_Project_Filter,
      Scratch_Filter);

   type Switcher_Metadata_Filter is record
      Kind : Switcher_Metadata_Filter_Kind := No_Filter;
      Text : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   type Switcher_Sort_Mode is
     (Default_Sort,
      Recent_Sort,
      Name_Sort,
      Pinned_Sort,
      Group_Sort,
      Label_Sort);

end Editor.Buffer_Switcher_Model.Filters;
