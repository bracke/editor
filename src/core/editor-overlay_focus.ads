with Editor.Panel_Focus;

package Editor.Overlay_Focus is

   type Overlay_Target is
     (No_Overlay,
      Command_Palette_Overlay,
      Quick_Open_Overlay,
      Buffer_Switcher_Overlay,
      Project_Search_Bar_Overlay,
      Active_Find_Prompt_Overlay,
      Go_To_Line_Overlay,
      File_Target_Prompt_Overlay);

   type Overlay_Dismissal_Reason is
     (Dismiss_Escape,
      Dismiss_Accept,
      Dismiss_Outside_Click,
      Dismiss_Replaced_By_Other_Overlay,
      Dismiss_Command);

   type Previous_Focus_Target is
     (Previous_Editor_Text,
      Previous_File_Tree,
      Previous_Search_Results,
      Previous_Problems,
      Previous_None);

   type Overlay_Focus_State is private;

   procedure Clear
     (State : in out Overlay_Focus_State);

   function Active_Overlay
     (State : Overlay_Focus_State) return Overlay_Target;

   function Has_Active_Overlay
     (State : Overlay_Focus_State) return Boolean;

   function Is_Active
     (State   : Overlay_Focus_State;
      Overlay : Overlay_Target) return Boolean;

   function Current_Panel_Focus_Target
     (Focus : Editor.Panel_Focus.Panel_Focus_State) return Previous_Focus_Target;

   procedure Activate
     (State          : in out Overlay_Focus_State;
      Overlay        : Overlay_Target;
      Previous_Focus : Editor.Panel_Focus.Panel_Focus_State);

   procedure Activate_With_Previous
     (State          : in out Overlay_Focus_State;
      Overlay        : Overlay_Target;
      Previous_Focus : Previous_Focus_Target);

   procedure Dismiss
     (State  : in out Overlay_Focus_State;
      Reason : Overlay_Dismissal_Reason);

   function Has_Previous_Focus
     (State : Overlay_Focus_State) return Boolean;

   function Previous_Focus
     (State : Overlay_Focus_State) return Previous_Focus_Target;

   function Last_Dismissal_Reason
     (State : Overlay_Focus_State) return Overlay_Dismissal_Reason;

private
   type Overlay_Focus_State is record
      Active        : Overlay_Target := No_Overlay;
      Previous      : Previous_Focus_Target := Previous_None;
      Last_Reason   : Overlay_Dismissal_Reason := Dismiss_Command;
   end record;

end Editor.Overlay_Focus;
