with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Pending_Transition_Bar;
with Editor.Pending_Transitions;
with Editor.Dirty_Guards;
with Editor.Commands;

package body Editor.Pending_Transition_Bar.Tests is

   use type Editor.Pending_Transition_Bar.Pending_Bar_Action;
   use type Editor.Pending_Transition_Bar.Pending_Bar_Hit_Zone;
   use type Editor.Commands.Command_Id;
   use type Editor.Pending_Transitions.Pending_Transition_Kind;

   function Name
     (T : Pending_Transition_Bar_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Pending_Transition_Bar.Tests");
   end Name;

   function Summary
     (Dirty : Natural := 3) return Editor.Dirty_Guards.Dirty_Buffer_Summary
   is
   begin
      return (Dirty_Count => Dirty, Untitled_Count => 1, File_Backed_Count => (if Dirty = 0 then 0 else Dirty - 1));
   end Summary;

   function Pending
     (Kind    : Editor.Pending_Transitions.Pending_Transition_Kind :=
                  Editor.Pending_Transitions.Pending_Open_Project;
      Display : String := "target")
      return Editor.Pending_Transitions.Pending_Transition_State
   is
      State : Editor.Pending_Transitions.Pending_Transition_State;
      Target : constant Editor.Pending_Transitions.Pending_Transition_Target :=
        (Kind       => Kind,
         Path       => To_Unbounded_String ("/tmp/target"),
         Display    => To_Unbounded_String (Display),
         Buffer_Id  => 7,
         Has_Buffer => Kind = Editor.Pending_Transitions.Pending_Close_Buffer,
         Has_Path   => True,
         others     => <>);
   begin
      Editor.Pending_Transitions.Set_Pending (State, Target, Summary);
      return State;
   end Pending;

   function Contains (Text, Part : String) return Boolean is
   begin
      return Ada.Strings.Fixed.Index (Text, Part) /= 0;
   end Contains;

   function Has_Action
     (Snapshot : Editor.Pending_Transition_Bar.Pending_Bar_Snapshot;
      Action   : Editor.Pending_Transition_Bar.Pending_Bar_Action) return Boolean
   is
   begin
      for I in 1 .. Editor.Pending_Transition_Bar.Action_Count (Snapshot) loop
         if Editor.Pending_Transition_Bar.Action (Snapshot, I).Action = Action then
            return True;
         end if;
      end loop;
      return False;
   end Has_Action;

   function Has_Action_Rect
     (Layout : Editor.Pending_Transition_Bar.Pending_Bar_Layout;
      Action : Editor.Pending_Transition_Bar.Pending_Bar_Action) return Boolean
   is
   begin
      for I in 1 .. Editor.Pending_Transition_Bar.Action_Rect_Count (Layout) loop
         if Editor.Pending_Transition_Bar.Action_Rect (Layout, I).Action = Action then
            return True;
         end if;
      end loop;
      return False;
   end Has_Action_Rect;

   procedure Test_No_Pending_Invisible
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Pending_Transitions.Pending_Transition_State;
      Snapshot : constant Editor.Pending_Transition_Bar.Pending_Bar_Snapshot :=
        Editor.Pending_Transition_Bar.Build_Snapshot (State, (others => <>));
   begin
      Assert (not Editor.Pending_Transition_Bar.Is_Visible (Snapshot),
              "bar snapshot must be invisible without pending transition");
      Assert (Editor.Pending_Transition_Bar.Action_Count (Snapshot) = 0,
              "invisible bar snapshot must have no actions");
   end Test_No_Pending_Invisible;

   procedure Test_Pending_Summary_And_Core_Actions
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Pending_Transition_Bar.Pending_Bar_Snapshot :=
        Editor.Pending_Transition_Bar.Build_Snapshot (Pending, (others => <>));
      Text : constant String := Editor.Pending_Transition_Bar.Summary_Text (Snapshot);
   begin
      Assert (Editor.Pending_Transition_Bar.Is_Visible (Snapshot),
              "bar snapshot must be visible for pending transition");
      Assert (Contains (Text, "project switch"),
              "summary must include operation kind");
      Assert (Contains (Text, "3 unsaved buffers"),
              "summary must include dirty count");
      Assert (Has_Action (Snapshot, Editor.Pending_Transition_Bar.Save_All_Action),
              "bar actions must include Save All");
      Assert (Has_Action (Snapshot, Editor.Pending_Transition_Bar.Retry_Pending_Transition_Action),
              "bar actions must include Retry");
      Assert (Has_Action (Snapshot, Editor.Pending_Transition_Bar.Discard_Pending_Transition_Action),
              "bar actions must include explicit Discard");
      Assert (Has_Action (Snapshot, Editor.Pending_Transition_Bar.Cancel_Pending_Transition_Action),
              "bar actions must include Cancel");
   end Test_Pending_Summary_And_Core_Actions;

   procedure Test_Command_Mapping
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Pending_Transition_Bar.Command_For_Action
                (Editor.Pending_Transition_Bar.Save_All_Action)
              = Editor.Commands.Command_Save_All,
              "Save All action must map to save-all command");
      Assert (Editor.Pending_Transition_Bar.Command_For_Action
                (Editor.Pending_Transition_Bar.Retry_Pending_Transition_Action)
              = Editor.Commands.Command_Retry_Pending_Transition,
              "Retry action must map to retry-pending command");
      Assert (Editor.Pending_Transition_Bar.Command_For_Action
                (Editor.Pending_Transition_Bar.Discard_Pending_Transition_Action)
              = Editor.Commands.Command_Discard_Pending_Transition,
              "Discard action must map to discard-pending command");
      Assert (Editor.Pending_Transition_Bar.Command_For_Action
                (Editor.Pending_Transition_Bar.Cancel_Pending_Transition_Action)
              = Editor.Commands.Command_Cancel_Pending_Transition,
              "Cancel action must map to cancel-pending command");
   end Test_Command_Mapping;

   procedure Test_Layout_Hit_Test
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Pending_Transition_Bar.Pending_Bar_Snapshot :=
        Editor.Pending_Transition_Bar.Build_Snapshot (Pending, (others => <>));
      Layout : constant Editor.Pending_Transition_Bar.Pending_Bar_Layout :=
        Editor.Pending_Transition_Bar.Layout (Snapshot, 0, 100, 900, 8, 16);
      Found_Cancel : Boolean := False;
   begin
      Assert (Editor.Pending_Transition_Bar.Action_Rect_Count (Layout) > 0,
              "wide bar layout must expose action rects");
      for I in 1 .. Editor.Pending_Transition_Bar.Action_Rect_Count (Layout) loop
         declare
            Rect : constant Editor.Pending_Transition_Bar.Pending_Bar_Action_Rect :=
              Editor.Pending_Transition_Bar.Action_Rect (Layout, I);
            Hit : constant Editor.Pending_Transition_Bar.Pending_Bar_Hit_Result :=
              Editor.Pending_Transition_Bar.Hit_Test
                (Snapshot, Layout, Rect.X + 1, Rect.Y + 1);
         begin
            Assert (Rect.X >= Editor.Pending_Transition_Bar.Bar_X (Layout)
                    and then Rect.Y >= Editor.Pending_Transition_Bar.Bar_Y (Layout)
                    and then Rect.X + Rect.W <= Editor.Pending_Transition_Bar.Bar_X (Layout)
                                             + Editor.Pending_Transition_Bar.Bar_W (Layout),
                    "action rect must remain inside bar bounds");
            Assert (Hit.Zone = Editor.Pending_Transition_Bar.Pending_Bar_Action_Zone
                    and then Hit.Action = Rect.Action,
                    "hit test inside action rect must return that action");
            if Rect.Action = Editor.Pending_Transition_Bar.Cancel_Pending_Transition_Action then
               Found_Cancel := True;
            end if;
         end;
      end loop;
      Assert (Found_Cancel, "layout must preserve Cancel on a wide bar");
      Assert (Editor.Pending_Transition_Bar.Hit_Test (Snapshot, Layout, 1, 101).Zone
              /= Editor.Pending_Transition_Bar.Outside_Pending_Bar,
              "click inside bar must not route outside");
      Assert (Editor.Pending_Transition_Bar.Hit_Test (Snapshot, Layout, 1, 10).Zone
              = Editor.Pending_Transition_Bar.Outside_Pending_Bar,
              "click outside bar must route outside");
   end Test_Layout_Hit_Test;

   procedure Test_Narrow_Layout_Preserves_Core_Actions
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Config : Editor.Pending_Transition_Bar.Pending_Bar_Config := (others => <>);
      Snapshot : Editor.Pending_Transition_Bar.Pending_Bar_Snapshot;
      Layout : Editor.Pending_Transition_Bar.Pending_Bar_Layout;
   begin
      Config.Minimum_Text_Columns := 12;
      Snapshot := Editor.Pending_Transition_Bar.Build_Snapshot (Pending, Config);
      Layout := Editor.Pending_Transition_Bar.Layout (Snapshot, 0, 100, 360, 8, 16);

      Assert (Has_Action_Rect
                (Layout, Editor.Pending_Transition_Bar.Cancel_Pending_Transition_Action),
              "narrow layout must preserve Cancel before optional actions");
      Assert (Has_Action_Rect
                (Layout, Editor.Pending_Transition_Bar.Retry_Pending_Transition_Action),
              "narrow layout must preserve Retry before optional actions");
      Assert (Has_Action_Rect
                (Layout, Editor.Pending_Transition_Bar.Discard_Pending_Transition_Action),
              "narrow layout must preserve explicit Discard before optional actions");
   end Test_Narrow_Layout_Preserves_Core_Actions;

   procedure Test_Action_Availability_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Editor.Pending_Transition_Bar.Pending_Bar_Snapshot :=
        Editor.Pending_Transition_Bar.Build_Snapshot (Pending, (others => <>));
      Found : Boolean := False;
   begin
      Editor.Pending_Transition_Bar.Set_Action_Availability
        (Snapshot, Editor.Pending_Transition_Bar.Save_All_Action, False);

      for I in 1 .. Editor.Pending_Transition_Bar.Action_Count (Snapshot) loop
         declare
            Info : constant Editor.Pending_Transition_Bar.Pending_Bar_Action_Info :=
              Editor.Pending_Transition_Bar.Action (Snapshot, I);
         begin
            if Info.Action = Editor.Pending_Transition_Bar.Save_All_Action then
               Found := True;
               Assert (not Info.Available,
                       "availability enrichment must update action metadata");
            end if;
         end;
      end loop;

      Assert (Found, "Save All action must still exist after availability update");
   end Test_Action_Availability_Metadata;

   procedure Test_Zero_Width_Layout_Is_Safe
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Pending_Transition_Bar.Pending_Bar_Snapshot :=
        Editor.Pending_Transition_Bar.Build_Snapshot (Pending, (others => <>));
      Layout : constant Editor.Pending_Transition_Bar.Pending_Bar_Layout :=
        Editor.Pending_Transition_Bar.Layout (Snapshot, 0, 0, 0, 8, 16);
   begin
      Assert (Editor.Pending_Transition_Bar.Action_Rect_Count (Layout) = 0,
              "zero-width layout must produce no action rects");
      Assert (Editor.Pending_Transition_Bar.Hit_Test (Snapshot, Layout, 0, 0).Zone
              = Editor.Pending_Transition_Bar.Outside_Pending_Bar,
              "zero-width layout must hit outside");
   end Test_Zero_Width_Layout_Is_Safe;

   procedure Test_Bar_Summary_Uses_Replaced_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Pending_Transitions.Pending_Transition_State;
      First_Target : constant Editor.Pending_Transitions.Pending_Transition_Target :=
        (Kind       => Editor.Pending_Transitions.Pending_Open_Project,
         Path       => To_Unbounded_String ("/tmp/a"),
         Display    => To_Unbounded_String ("Project A"),
         Buffer_Id  => 0,
         Has_Buffer => False,
         Has_Path   => True,
         others     => <>);
      Second_Target : constant Editor.Pending_Transitions.Pending_Transition_Target :=
        (Kind       => Editor.Pending_Transitions.Pending_Open_Project,
         Path       => To_Unbounded_String ("/tmp/b"),
         Display    => To_Unbounded_String ("Project B"),
         Buffer_Id  => 0,
         Has_Buffer => False,
         Has_Path   => True,
         others     => <>);
      Snapshot : Editor.Pending_Transition_Bar.Pending_Bar_Snapshot;
      Text     : Unbounded_String;
   begin
      Editor.Pending_Transitions.Set_Pending (State, First_Target, Summary);
      Editor.Pending_Transitions.Set_Pending (State, Second_Target, Summary);
      Snapshot := Editor.Pending_Transition_Bar.Build_Snapshot (State, (others => <>));
      Text := To_Unbounded_String
        (Editor.Pending_Transition_Bar.Summary_Text (Snapshot));

      Assert (Ada.Strings.Unbounded.Index (Text, "Project B") /= 0,
              "pending bar summary must show the replacement target");
      Assert (Ada.Strings.Unbounded.Index (Text, "Project A") = 0,
              "pending bar summary must not retain the replaced target");
   end Test_Bar_Summary_Uses_Replaced_Target;

   procedure Test_Phase573_Reload_And_Revert_Operations_Are_Named
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Reload_Snapshot : constant Editor.Pending_Transition_Bar.Pending_Bar_Snapshot :=
        Editor.Pending_Transition_Bar.Build_Snapshot
          (Pending
             (Kind    => Editor.Pending_Transitions.Pending_Reload_Active_Buffer,
              Display => "main.adb"),
           (others => <>));
      Revert_Snapshot : constant Editor.Pending_Transition_Bar.Pending_Bar_Snapshot :=
        Editor.Pending_Transition_Bar.Build_Snapshot
          (Pending
             (Kind    => Editor.Pending_Transitions.Pending_Revert_Active_Buffer,
              Display => "main.adb"),
           (others => <>));
      Close_All_Snapshot : constant Editor.Pending_Transition_Bar.Pending_Bar_Snapshot :=
        Editor.Pending_Transition_Bar.Build_Snapshot
          (Pending
             (Kind    => Editor.Pending_Transitions.Pending_Close_All_Buffers,
              Display => "all buffers"),
           (others => <>));
   begin
      Assert
        (Contains
           (Editor.Pending_Transition_Bar.Summary_Text (Reload_Snapshot),
            "reloading buffer from disk"),
         "reload confirmation must name the reload operation");
      Assert
        (Contains
           (Editor.Pending_Transition_Bar.Summary_Text (Reload_Snapshot),
            "main.adb"),
         "reload confirmation must include the affected buffer label");
      Assert
        (Contains
           (Editor.Pending_Transition_Bar.Summary_Text (Revert_Snapshot),
            "reverting buffer"),
         "revert confirmation must name the revert operation");
      Assert
        (Contains
           (Editor.Pending_Transition_Bar.Summary_Text (Revert_Snapshot),
            "main.adb"),
         "revert confirmation must include the affected buffer label");
      Assert
        (Contains
           (Editor.Pending_Transition_Bar.Summary_Text (Close_All_Snapshot),
            "closing all buffers"),
         "close-all confirmation must name the close-all operation");
   end Test_Phase573_Reload_And_Revert_Operations_Are_Named;

   procedure Test_Phase573_Reload_And_Revert_Actions_Are_Lifecycle_Scoped
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Reload_Snapshot : constant Editor.Pending_Transition_Bar.Pending_Bar_Snapshot :=
        Editor.Pending_Transition_Bar.Build_Snapshot
          (Pending
             (Kind    => Editor.Pending_Transitions.Pending_Reload_Active_Buffer,
              Display => "main.adb"),
           (others => <>));
      Revert_Snapshot : constant Editor.Pending_Transition_Bar.Pending_Bar_Snapshot :=
        Editor.Pending_Transition_Bar.Build_Snapshot
          (Pending
             (Kind    => Editor.Pending_Transitions.Pending_Revert_Active_Buffer,
              Display => "main.adb"),
           (others => <>));
   begin
      Assert (Has_Action (Reload_Snapshot, Editor.Pending_Transition_Bar.Retry_Pending_Transition_Action),
              "reload confirmation must expose Retry");
      Assert (Has_Action (Reload_Snapshot, Editor.Pending_Transition_Bar.Cancel_Pending_Transition_Action),
              "reload confirmation must expose Cancel");
      Assert (not Has_Action (Reload_Snapshot, Editor.Pending_Transition_Bar.Save_All_Action),
              "reload confirmation must not expose Save All");
      Assert (not Has_Action (Reload_Snapshot, Editor.Pending_Transition_Bar.Discard_Pending_Transition_Action),
              "reload confirmation must not expose Discard");
      Assert (not Has_Action (Reload_Snapshot, Editor.Pending_Transition_Bar.Close_All_Clean_Buffers_Action),
              "reload confirmation must not expose Close Clean");
      Assert (Has_Action (Revert_Snapshot, Editor.Pending_Transition_Bar.Retry_Pending_Transition_Action),
              "revert confirmation must expose Retry");
      Assert (Has_Action (Revert_Snapshot, Editor.Pending_Transition_Bar.Cancel_Pending_Transition_Action),
              "revert confirmation must expose Cancel");
      Assert (not Has_Action (Revert_Snapshot, Editor.Pending_Transition_Bar.Save_All_Action),
              "revert confirmation must not expose Save All");
      Assert (not Has_Action (Revert_Snapshot, Editor.Pending_Transition_Bar.Discard_Pending_Transition_Action),
              "revert confirmation must not expose Discard");
      Assert (not Has_Action (Revert_Snapshot, Editor.Pending_Transition_Bar.Close_All_Clean_Buffers_Action),
              "revert confirmation must not expose Close Clean");
   end Test_Phase573_Reload_And_Revert_Actions_Are_Lifecycle_Scoped;


   procedure Test_Wide_Action_Order_Is_Final
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Pending_Transition_Bar.Pending_Bar_Snapshot :=
        Editor.Pending_Transition_Bar.Build_Snapshot (Pending, (others => <>));
   begin
      Assert (Editor.Pending_Transition_Bar.Action_Count (Snapshot) >= 5,
              "default snapshot must include the five final primary actions");
      Assert (Editor.Pending_Transition_Bar.Action (Snapshot, 1).Action =
                Editor.Pending_Transition_Bar.Save_All_Action,
              "first pending bar action must be Save All");
      Assert (Editor.Pending_Transition_Bar.Action (Snapshot, 2).Action =
                Editor.Pending_Transition_Bar.Discard_Pending_Transition_Action,
              "second pending bar action must be explicit Discard");
      Assert (Editor.Pending_Transition_Bar.Action (Snapshot, 3).Action =
                Editor.Pending_Transition_Bar.Retry_Pending_Transition_Action,
              "third pending bar action must be Retry");
      Assert (Editor.Pending_Transition_Bar.Action (Snapshot, 4).Action =
                Editor.Pending_Transition_Bar.Cancel_Pending_Transition_Action,
              "fourth pending bar action must be Cancel");
      Assert (Editor.Pending_Transition_Bar.Action (Snapshot, 5).Action =
                Editor.Pending_Transition_Bar.Close_All_Clean_Buffers_Action,
              "fifth pending bar action must be Close Clean");
   end Test_Wide_Action_Order_Is_Final;


   overriding procedure Register_Tests
     (T : in out Pending_Transition_Bar_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_No_Pending_Invisible'Access,
                        "no pending transition hides pending bar");
      Register_Routine (T, Test_Pending_Summary_And_Core_Actions'Access,
                        "pending transition shows summary and core actions");
      Register_Routine (T, Test_Command_Mapping'Access,
                        "bar actions map to command ids");
      Register_Routine (T, Test_Layout_Hit_Test'Access,
                        "layout and hit testing are deterministic");
      Register_Routine (T, Test_Narrow_Layout_Preserves_Core_Actions'Access,
                        "narrow layout preserves core actions before optional actions");
      Register_Routine (T, Test_Action_Availability_Metadata'Access,
                        "action availability metadata can be enriched by integration layer");
      Register_Routine (T, Test_Zero_Width_Layout_Is_Safe'Access,
                        "zero-width layout is safe");
      Register_Routine (T, Test_Bar_Summary_Uses_Replaced_Target'Access,
                        "bar summary uses replacement target");
      Register_Routine (T, Test_Wide_Action_Order_Is_Final'Access,
                        "wide bar action order is final");
      Register_Routine
        (T, Test_Phase573_Reload_And_Revert_Operations_Are_Named'Access,
         "phase 573 reload/revert pending bar names operation and buffer");
      Register_Routine
        (T, Test_Phase573_Reload_And_Revert_Actions_Are_Lifecycle_Scoped'Access,
         "phase 573 reload/revert pending bar exposes only retry/cancel");
   end Register_Tests;

end Editor.Pending_Transition_Bar.Tests;
