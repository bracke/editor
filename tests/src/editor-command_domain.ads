with Editor.State;

package Editor.Command_Domain is

   type Command_Side_Effect_Domain is
     (Domain_None,
      Domain_Buffers,
      Domain_Dirty_State,
      Domain_Project,
      Domain_Project_Scoped_UI,
      Domain_Workspace_File,
      Domain_Settings_Runtime,
      Domain_Settings_File,
      Domain_Keybindings_Runtime,
      Domain_Keybindings_File,
      Domain_Recent_Projects,
      Domain_Pending_Transition,
      Domain_Messages,
      Domain_Search_State,
      Domain_Panel_State,
      Domain_Render_Projection,
      Domain_Feature_Runtime_State,
      Domain_Feature_Project_State,
      Domain_Feature_Workspace_State,
      Domain_Feature_Settings,
      Domain_Feature_Render_Projection,
      Domain_Feature_Panel_State);

   type Command_Side_Effect_Domain_Set is
     array (Command_Side_Effect_Domain) of Boolean;

   No_Domains : constant Command_Side_Effect_Domain_Set := (others => False);

   type Command_Domain_Summary is record
      Buffer_Count              : Natural := 0;
      Dirty_Buffer_Count        : Natural := 0;
      Has_Project               : Boolean := False;
      Recent_Project_Count      : Natural := 0;
      Recent_Project_Selection  : Natural := 0;
      Has_Pending_Transition    : Boolean := False;
      Settings_Fingerprint      : Natural := 0;
      Keybindings_Fingerprint   : Natural := 0;
      Message_Count             : Natural := 0;
      Search_Fingerprint        : Natural := 0;
      Panel_Fingerprint         : Natural := 0;
   end record;

   function Summary
     (S : Editor.State.State_Type) return Command_Domain_Summary;

   function Settings_Fingerprint
     (S : Editor.State.State_Type) return Natural;

   function Active_Keybindings_Fingerprint return Natural;

   function Command_Metadata_Fingerprint return Natural;

   procedure Assert_Command_Mutates_Only
     (Before  : Editor.State.State_Type;
      After   : Editor.State.State_Type;
      Allowed : Command_Side_Effect_Domain_Set;
      Context : String);

end Editor.Command_Domain;
