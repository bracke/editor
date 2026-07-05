with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Dirty_Guards;
with Editor.Commands;
with Editor.Pending_Transitions;

package body Editor.Pending_Transition_Bar is

   use type Editor.Pending_Transitions.Pending_Transition_Kind;
   use type Editor.Commands.Command_Id;

   type Pending_Bar_Action_Order is array (Positive range <>) of Pending_Bar_Action;

   function Count_Text (Count : Natural) return String is
   begin
      return Ada.Strings.Fixed.Trim (Natural'Image (Count), Ada.Strings.Both);
   end Count_Text;

   function Dirty_Count_Text
     (Summary : Editor.Dirty_Guards.Dirty_Buffer_Summary) return String
   is
   begin
      if Summary.Dirty_Count = 1 then
         return "1 unsaved buffer";
      else
         return Count_Text (Summary.Dirty_Count) & " unsaved buffers";
      end if;
   end Dirty_Count_Text;

   function Operation_Text
     (Target : Editor.Pending_Transitions.Pending_Transition_Target) return String
   is
   begin
      case Target.Kind is
         when Editor.Pending_Transitions.No_Pending_Transition =>
            return "transition";
         when Editor.Pending_Transitions.Pending_Close_Buffer =>
            return "closing buffer";
         when Editor.Pending_Transitions.Pending_Close_All_Buffers =>
            return "closing all buffers";
         when Editor.Pending_Transitions.Pending_Close_Other_Buffers =>
            return "closing other buffers";
         when Editor.Pending_Transitions.Pending_Reload_Active_Buffer =>
            return "reloading buffer from disk";
         when Editor.Pending_Transitions.Pending_Revert_Active_Buffer =>
            return "reverting buffer";
         when Editor.Pending_Transitions.Pending_Close_Project =>
            return "closing project";
         when Editor.Pending_Transitions.Pending_Clear_Project =>
            return "clearing project context";
         when Editor.Pending_Transitions.Pending_Open_Project
            | Editor.Pending_Transitions.Pending_Switch_Project
            | Editor.Pending_Transitions.Pending_Open_Recent_Project =>
            return "project switch";
         when Editor.Pending_Transitions.Pending_Restore_Workspace =>
            return "workspace restore";
         when Editor.Pending_Transitions.Pending_Clear_Workspace_State =>
            return "clearing workspace state";
      end case;
   end Operation_Text;

   function Guidance_For_Target
     (Target : Editor.Pending_Transitions.Pending_Transition_Target) return String
   is
   begin
      case Target.Kind is
         when Editor.Pending_Transitions.Pending_Reload_Active_Buffer =>
            return "Retry reload after saving, or cancel to keep editing";
         when Editor.Pending_Transitions.Pending_Revert_Active_Buffer =>
            return "Discard editor changes only when you want the disk version";
         when Editor.Pending_Transitions.Pending_Open_Project
            | Editor.Pending_Transitions.Pending_Switch_Project
            | Editor.Pending_Transitions.Pending_Open_Recent_Project =>
            return "Save changes before switching projects";
         when Editor.Pending_Transitions.Pending_Restore_Workspace =>
            return "Save changes before restoring the workspace";
         when Editor.Pending_Transitions.Pending_Close_Project
            | Editor.Pending_Transitions.Pending_Clear_Project =>
            return "Save or discard project changes before continuing";
         when Editor.Pending_Transitions.Pending_Clear_Workspace_State =>
            return "Confirm clear only after reviewing the workspace state";
         when Editor.Pending_Transitions.Pending_Close_Buffer
            | Editor.Pending_Transitions.Pending_Close_All_Buffers
            | Editor.Pending_Transitions.Pending_Close_Other_Buffers =>
            return "Save or discard buffer changes before closing";
         when Editor.Pending_Transitions.No_Pending_Transition =>
            return "";
      end case;
   end Guidance_For_Target;

   function Operation_For_Target
     (Target : Editor.Pending_Transitions.Pending_Transition_Target)
      return Pending_Bar_Operation
   is
   begin
      case Target.Kind is
         when Editor.Pending_Transitions.No_Pending_Transition =>
            return No_Pending_Bar_Operation;
         when Editor.Pending_Transitions.Pending_Close_Buffer =>
            return Pending_Bar_Close_Buffer_Operation;
         when Editor.Pending_Transitions.Pending_Close_All_Buffers =>
            return Pending_Bar_Close_All_Buffers_Operation;
         when Editor.Pending_Transitions.Pending_Close_Other_Buffers =>
            return Pending_Bar_Close_Other_Buffers_Operation;
         when Editor.Pending_Transitions.Pending_Reload_Active_Buffer =>
            return Pending_Bar_Reload_Buffer_Operation;
         when Editor.Pending_Transitions.Pending_Revert_Active_Buffer =>
            return Pending_Bar_Revert_Buffer_Operation;
         when Editor.Pending_Transitions.Pending_Close_Project =>
            return Pending_Bar_Close_Project_Operation;
         when Editor.Pending_Transitions.Pending_Clear_Project =>
            return Pending_Bar_Clear_Project_Operation;
         when Editor.Pending_Transitions.Pending_Open_Project
            | Editor.Pending_Transitions.Pending_Switch_Project
            | Editor.Pending_Transitions.Pending_Open_Recent_Project =>
            return Pending_Bar_Project_Switch_Operation;
         when Editor.Pending_Transitions.Pending_Restore_Workspace =>
            return Pending_Bar_Restore_Workspace_Operation;
         when Editor.Pending_Transitions.Pending_Clear_Workspace_State =>
            return Pending_Bar_Clear_Workspace_State_Operation;
      end case;
   end Operation_For_Target;

   function Is_Destructive_Target
     (Target : Editor.Pending_Transitions.Pending_Transition_Target) return Boolean
   is
   begin
      return Target.Kind in
        Editor.Pending_Transitions.Pending_Clear_Project
          | Editor.Pending_Transitions.Pending_Revert_Active_Buffer
          | Editor.Pending_Transitions.Pending_Clear_Workspace_State;
   end Is_Destructive_Target;

   function Snapshot_Summary
     (Pending : Editor.Pending_Transitions.Pending_Transition_State) return String
   is
      Target  : constant Editor.Pending_Transitions.Pending_Transition_Target :=
        Editor.Pending_Transitions.Target (Pending);
      Summary : constant Editor.Dirty_Guards.Dirty_Buffer_Summary :=
        Editor.Pending_Transitions.Dirty_Summary (Pending);
      Display : constant String := To_String (Target.Display);
   begin
      if Target.Kind = Editor.Pending_Transitions.Pending_Clear_Workspace_State then
         if Display'Length > 0 then
            return "Clear " & Display & "?";
         elsif Target.Has_Path then
            return "Clear workspace state: " & To_String (Target.Path) & "?";
         else
            return "Clear workspace state?";
         end if;
      end if;

      if Display'Length > 0 then
         return "Unsaved changes block " & Operation_Text (Target)
           & ": " & Display
           & " (" & Dirty_Count_Text (Summary) & ")";
      end if;

      return "Unsaved changes block " & Operation_Text (Target)
        & ": " & Dirty_Count_Text (Summary);
   end Snapshot_Summary;

   function Command_For_Action
     (Action : Pending_Bar_Action) return Editor.Commands.Command_Id
   is
   begin
      case Action is
         when No_Pending_Bar_Action =>
            return Editor.Commands.No_Command;
         when Save_All_Action =>
            return Editor.Commands.Command_Save_All;
         when Close_All_Clean_Buffers_Action =>
            return Editor.Commands.Command_Close_All_Clean_Buffers;
         when Retry_Pending_Transition_Action =>
            return Editor.Commands.Command_Retry_Pending_Transition;
         when Discard_Pending_Transition_Action =>
            return Editor.Commands.Command_Discard_Pending_Transition;
         when Cancel_Pending_Transition_Action =>
            return Editor.Commands.Command_Cancel_Pending_Transition;
      end case;
   end Command_For_Action;

   function Label_For_Action (Action : Pending_Bar_Action) return String is
   begin
      case Action is
         when No_Pending_Bar_Action =>
            return "";
         when Save_All_Action =>
            return "Save All";
         when Close_All_Clean_Buffers_Action =>
            return "Close Clean";
         when Retry_Pending_Transition_Action =>
            return "Retry";
         when Discard_Pending_Transition_Action =>
            return "Discard";
         when Cancel_Pending_Transition_Action =>
            return "Cancel";
      end case;
   end Label_For_Action;

   function Is_Destructive (Action : Pending_Bar_Action) return Boolean is
   begin
      return Action = Discard_Pending_Transition_Action;
   end Is_Destructive;

   procedure Append_Action
     (Snapshot : in out Pending_Bar_Snapshot;
      Action   : Pending_Bar_Action)
   is
   begin
      if Action = No_Pending_Bar_Action
        or else Snapshot.Count >= Max_Pending_Bar_Actions
      then
         return;
      end if;

      Snapshot.Count := Snapshot.Count + 1;
      Snapshot.Actions (Snapshot.Count) :=
        (Action         => Action,
         Command        => Command_For_Action (Action),
         Label          => To_Unbounded_String (Label_For_Action (Action)),
         Available      => True,
         Is_Destructive => Is_Destructive (Action));
   end Append_Action;

   function Build_Snapshot
     (Pending : Editor.Pending_Transitions.Pending_Transition_State;
      Config  : Pending_Bar_Config) return Pending_Bar_Snapshot
   is
      Result : Pending_Bar_Snapshot;
      Limit  : constant Natural := Natural'Min (Config.Max_Actions, Max_Pending_Bar_Actions);
   begin
      Result.Height_Rows := Natural'Max (1, Config.Height_Rows);
      Result.Minimum_Text_Columns := Config.Minimum_Text_Columns;

      if not Editor.Pending_Transitions.Has_Pending (Pending)
        or else Limit = 0
      then
         return Result;
      end if;

      Result.Visible := True;
      Result.Summary := To_Unbounded_String (Snapshot_Summary (Pending));

      declare
         Target : constant Editor.Pending_Transitions.Pending_Transition_Target :=
           Editor.Pending_Transitions.Target (Pending);
         File_Lifecycle_Confirmation : constant Boolean :=
           Target.Kind in
             Editor.Pending_Transitions.Pending_Reload_Active_Buffer
               | Editor.Pending_Transitions.Pending_Revert_Active_Buffer
               | Editor.Pending_Transitions.Pending_Clear_Workspace_State;
      begin
         Result.Guidance := To_Unbounded_String (Guidance_For_Target (Target));
         Result.Operation := Operation_For_Target (Target);
         Result.Destructive := Is_Destructive_Target (Target);

         --  completeness: reload/revert confirmations are not
         --  project/close transitions and must not expose unrelated cleanup
         --  actions in the pending bar.  Save All and Close Clean remain
         --  available for broader dirty-transition prompts, but a dirty
         --  reload/revert prompt has exactly the same lifecycle-specific
         --  surface as its confirmation text: Retry or Cancel.
         if not File_Lifecycle_Confirmation then
            Append_Action (Result, Save_All_Action);
         end if;

         if (not File_Lifecycle_Confirmation) and then Result.Count < Limit then
            Append_Action (Result, Discard_Pending_Transition_Action);
         end if;
         if Config.Show_Retry and then Result.Count < Limit then
            Append_Action (Result, Retry_Pending_Transition_Action);
         end if;
         if Config.Show_Cancel and then Result.Count < Limit then
            Append_Action (Result, Cancel_Pending_Transition_Action);
         end if;
         if (not File_Lifecycle_Confirmation)
           and then Config.Show_Close_Clean
           and then Result.Count < Limit
         then
            Append_Action (Result, Close_All_Clean_Buffers_Action);
         end if;
      end;

      return Result;
   end Build_Snapshot;

   function Is_Visible
     (Snapshot : Pending_Bar_Snapshot) return Boolean
   is
   begin
      return Snapshot.Visible;
   end Is_Visible;

   function Summary_Text
     (Snapshot : Pending_Bar_Snapshot) return String
   is
   begin
      return To_String (Snapshot.Summary);
   end Summary_Text;

   function Guidance_Text
     (Snapshot : Pending_Bar_Snapshot) return String
   is
   begin
      return To_String (Snapshot.Guidance);
   end Guidance_Text;

   function Display_Text
     (Snapshot : Pending_Bar_Snapshot) return String
   is
      Summary  : constant String := Summary_Text (Snapshot);
      Guidance : constant String := Guidance_Text (Snapshot);
   begin
      if Guidance'Length = 0 then
         return Summary;
      else
         return Summary & " - " & Guidance;
      end if;
   end Display_Text;

   function Action_Count
     (Snapshot : Pending_Bar_Snapshot) return Natural
   is
   begin
      return Snapshot.Count;
   end Action_Count;

   function Operation
     (Snapshot : Pending_Bar_Snapshot) return Pending_Bar_Operation
   is
   begin
      return Snapshot.Operation;
   end Operation;

   function Requires_Destructive_Confirmation
     (Snapshot : Pending_Bar_Snapshot) return Boolean
   is
   begin
      return Snapshot.Visible and then Snapshot.Destructive;
   end Requires_Destructive_Confirmation;

   function Assert_Action_Routes_Are_Command_Backed
     (Snapshot : Pending_Bar_Snapshot) return Boolean
   is
   begin
      if not Snapshot.Visible then
         return Snapshot.Count = 0;
      end if;

      for I in 1 .. Snapshot.Count loop
         if Snapshot.Actions (I).Action = No_Pending_Bar_Action
           or else Snapshot.Actions (I).Command = Editor.Commands.No_Command
           or else Snapshot.Actions (I).Command /=
             Command_For_Action (Snapshot.Actions (I).Action)
         then
            return False;
         end if;
      end loop;

      return True;
   end Assert_Action_Routes_Are_Command_Backed;

   function Assert_Destructive_Actions_Are_Confirmed
     (Snapshot : Pending_Bar_Snapshot) return Boolean
   is
      Has_Retry  : Boolean := False;
      Has_Cancel : Boolean := False;
   begin
      if not Snapshot.Visible then
         return not Snapshot.Destructive;
      end if;

      for I in 1 .. Snapshot.Count loop
         if Snapshot.Actions (I).Action = Retry_Pending_Transition_Action then
            Has_Retry := True;
         elsif Snapshot.Actions (I).Action = Cancel_Pending_Transition_Action then
            Has_Cancel := True;
         elsif Snapshot.Actions (I).Is_Destructive
           and then Snapshot.Actions (I).Command = Editor.Commands.No_Command
         then
            return False;
         end if;
      end loop;

      return (not Snapshot.Destructive) or else (Has_Retry and then Has_Cancel);
   end Assert_Destructive_Actions_Are_Confirmed;

   function Assert_Pending_Bar_Route_Audit_Passes
     (Snapshot : Pending_Bar_Snapshot) return Boolean
   is
   begin
      return Assert_Action_Routes_Are_Command_Backed (Snapshot)
        and then Assert_Destructive_Actions_Are_Confirmed (Snapshot);
   end Assert_Pending_Bar_Route_Audit_Passes;

   function Action
     (Snapshot : Pending_Bar_Snapshot;
      Index    : Positive) return Pending_Bar_Action_Info
   is
   begin
      if Index > Snapshot.Count then
         return (Action         => No_Pending_Bar_Action,
                 Command        => Editor.Commands.No_Command,
                 Label          => Null_Unbounded_String,
                 Available      => False,
                 Is_Destructive => False);
      end if;
      return Snapshot.Actions (Index);
   end Action;

   procedure Set_Action_Availability
     (Snapshot  : in out Pending_Bar_Snapshot;
      Action    : Pending_Bar_Action;
      Available : Boolean)
   is
   begin
      for I in 1 .. Snapshot.Count loop
         if Snapshot.Actions (I).Action = Action then
            Snapshot.Actions (I).Available := Available;
            return;
         end if;
      end loop;
   end Set_Action_Availability;

   function Action_Column_Width
     (Info : Pending_Bar_Action_Info) return Natural
   is
   begin
      if Length (Info.Label) = 0 then
         return 0;
      end if;
      return Length (Info.Label) + 4;
   end Action_Column_Width;

   function Layout
     (Snapshot : Pending_Bar_Snapshot;
      Bounds_X : Integer;
      Bounds_Y : Integer;
      Bounds_W : Integer;
      Cell_W   : Natural;
      Cell_H   : Natural) return Pending_Bar_Layout
   is
      Result : Pending_Bar_Layout;
      Bar_H  : Natural := 0;
      Used_W : Natural := 0;
      Right  : Integer := 0;
      Min_Text_W : Natural := 0;
   begin
      if not Snapshot.Visible
        or else Bounds_W <= 0
        or else Cell_W = 0
        or else Cell_H = 0
      then
         return Result;
      end if;

      Bar_H := Natural'Max (1, Snapshot.Height_Rows) * Cell_H;
      Result.Visible := True;
      Result.X := Bounds_X;
      Result.Y := Bounds_Y;
      Result.W := Bounds_W;
      Result.H := Integer (Bar_H);
      Right := Bounds_X + Bounds_W - Integer (Cell_W);
      Min_Text_W := Natural'Min
        (Natural (Integer'Max (0, Bounds_W)),
         Natural'Max (1, Snapshot.Minimum_Text_Columns) * Cell_W);

      --  Priority from the right edge: Cancel, Retry, Discard, Save All, Close Clean.
      declare
         Priority : constant Pending_Bar_Action_Order :=
           (Cancel_Pending_Transition_Action,
            Retry_Pending_Transition_Action,
            Discard_Pending_Transition_Action,
            Save_All_Action,
            Close_All_Clean_Buffers_Action);
      begin
         for Preferred of Priority loop
         for I in 1 .. Snapshot.Count loop
            if Snapshot.Actions (I).Action = Preferred then
               declare
                  Info  : constant Pending_Bar_Action_Info := Snapshot.Actions (I);
                  Width : constant Natural := Action_Column_Width (Info) * Cell_W;
               begin
                  if Width > 0
                    and then Natural (Bounds_W) > Used_W + Width + Min_Text_W
                    and then Result.Rect_Count < Max_Pending_Bar_Actions
                  then
                     Right := Right - Integer (Width);
                     Result.Rect_Count := Result.Rect_Count + 1;
                     Result.Rects (Result.Rect_Count) :=
                       (Action => Info.Action,
                        X      => Right,
                        Y      => Bounds_Y,
                        W      => Integer (Width),
                        H      => Integer (Bar_H));
                     Used_W := Used_W + Width;
                  end if;
               end;
            end if;
         end loop;
      end loop;
      end;

      return Result;
   end Layout;

   function Action_Rect_Count
     (Layout : Pending_Bar_Layout) return Natural
   is
   begin
      return Layout.Rect_Count;
   end Action_Rect_Count;

   function Action_Rect
     (Layout : Pending_Bar_Layout;
      Index  : Positive) return Pending_Bar_Action_Rect
   is
   begin
      if Index > Layout.Rect_Count then
         return (Action => No_Pending_Bar_Action, X => 0, Y => 0, W => 0, H => 0);
      end if;
      return Layout.Rects (Index);
   end Action_Rect;

   function Bar_X (Layout : Pending_Bar_Layout) return Integer is
   begin
      return Layout.X;
   end Bar_X;

   function Bar_Y (Layout : Pending_Bar_Layout) return Integer is
   begin
      return Layout.Y;
   end Bar_Y;

   function Bar_W (Layout : Pending_Bar_Layout) return Integer is
   begin
      return Layout.W;
   end Bar_W;

   function Bar_H (Layout : Pending_Bar_Layout) return Integer is
   begin
      return Layout.H;
   end Bar_H;

   function Hit_Test
     (Snapshot : Pending_Bar_Snapshot;
      Layout   : Pending_Bar_Layout;
      X        : Integer;
      Y        : Integer) return Pending_Bar_Hit_Result
   is
      pragma Unreferenced (Snapshot);
   begin
      if not Layout.Visible
        or else X < Layout.X
        or else Y < Layout.Y
        or else X >= Layout.X + Layout.W
        or else Y >= Layout.Y + Layout.H
      then
         return (Zone => Outside_Pending_Bar, Action => No_Pending_Bar_Action);
      end if;

      for I in 1 .. Layout.Rect_Count loop
         declare
            Rect : constant Pending_Bar_Action_Rect := Layout.Rects (I);
         begin
            if X >= Rect.X
              and then Y >= Rect.Y
              and then X < Rect.X + Rect.W
              and then Y < Rect.Y + Rect.H
            then
               return (Zone => Pending_Bar_Action_Zone, Action => Rect.Action);
            end if;
         end;
      end loop;

      return (Zone => Pending_Bar_Background, Action => No_Pending_Bar_Action);
   end Hit_Test;

end Editor.Pending_Transition_Bar;
