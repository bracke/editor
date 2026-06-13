with Editor.State;

package Editor.Feature_Panel.Fixtures is

   --  Populate deterministic feature-panel rows for tests.  This fixture
   --  replaces the old production placeholder-population helper so product
   --  code no longer exposes demo rows as a normal API.
   procedure Set_Placeholder_Rows
     (Panel : in out Feature_Panel_State);

   function State_With_Feature_Panel_Hidden
     return Editor.State.State_Type;

   function State_With_Feature_Panel_Visible
     return Editor.State.State_Type;

   function State_With_Feature_Panel_Focused
     return Editor.State.State_Type;

   function State_With_Feature_Panel_Rows
     return Editor.State.State_Type;

   function State_With_Feature_Panel_Selected_Row
     return Editor.State.State_Type;

   function State_With_Feature_Panel_Visible_And_Empty
     return Editor.State.State_Type;

   function State_With_Project_And_Feature_Panel_Rows
     return Editor.State.State_Type;

   function State_With_Dirty_Buffer_And_Feature_Panel_Rows
     return Editor.State.State_Type;

   function State_With_Pending_Transition_And_Feature_Panel_Rows
     return Editor.State.State_Type;

   function State_With_Command_Palette_And_Feature_Panel_Rows
     return Editor.State.State_Type;

   function State_With_Custom_Keybindings_For_Feature_Panel
     return Editor.State.State_Type;

end Editor.Feature_Panel.Fixtures;
