with Ada.Strings.Unbounded;
with Editor.Commands;

package Editor.Feature_Integration is

   type Feature_Integration_Status is
     (Feature_Integration_Ok,
      Feature_Integration_Failed);

   type Feature_Command_Kind is
     (Feature_View_Toggle,
      Feature_Navigation,
      Feature_Panel_Action,
      Feature_Configuration,
      Feature_Destructive,
      Feature_Lifecycle,
      Feature_Internal);

   type Feature_Side_Effect_Domain is
     (Domain_Feature_Runtime_State,
      Domain_Feature_Project_State,
      Domain_Feature_Workspace_State,
      Domain_Feature_Settings,
      Domain_Feature_Render_Projection,
      Domain_Feature_Panel_State);

   type Feature_Side_Effect_Domain_Set is
     array (Feature_Side_Effect_Domain) of Boolean;

   No_Feature_Domains : constant Feature_Side_Effect_Domain_Set := (others => False);

   type Feature_Command_Contract is record
      Command                    : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Kind                       : Feature_Command_Kind := Feature_Internal;
      Has_Descriptor             : Boolean := False;
      Has_Stable_Name            : Boolean := False;
      Stable_Name_Round_Trips    : Boolean := False;
      Has_Availability           : Boolean := False;
      Has_Executor_Handling      : Boolean := False;
      Destructive_Classified     : Boolean := False;
      Lifecycle_Classified       : Boolean := False;
      Configuration_Classified   : Boolean := False;
      Bindable                   : Boolean := False;
      Expected_Domains           : Feature_Side_Effect_Domain_Set := No_Feature_Domains;
   end record;

   type Feature_Route_Contract is record
      Source                    : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Expected_Command          : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Actual_Command            : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Reached_Executor          : Boolean := False;
      Mutated_Before_Executor   : Boolean := False;
      Executor_Dispatch_Count   : Natural := 0;
   end record;

   type Feature_Render_Projection_Contract is record
      Has_Explicit_Layer             : Boolean := False;
      Uses_Theme_Colours             : Boolean := False;
      Mutates_Feature_State          : Boolean := False;
      Mutates_Command_State          : Boolean := False;
      Mutates_Configuration_State    : Boolean := False;
      Mutates_Lifecycle_State        : Boolean := False;
      Corrupts_Existing_Layer_Order  : Boolean := False;
   end record;

   type Feature_Persistence_Contract is record
      Persists_To_Settings      : Boolean := False;
      Persists_To_Keybindings   : Boolean := False;
      Persists_To_Workspace     : Boolean := False;
      Persists_To_Recent        : Boolean := False;
      Persists_Dirty_Text       : Boolean := False;
      Persists_Pending_State    : Boolean := False;
      Explicit_Scope_Declared   : Boolean := False;
   end record;

   type Feature_Integration_Result is private;

   --  Reset a local feature-integration audit result. This helper is test-only
   --  scaffolding and never executes commands or mutates editor state.
   procedure Clear
     (Result : in out Feature_Integration_Result);

   --  Add one feature-integration failure associated with a command id.
   procedure Add_Failure
     (Result  : in out Feature_Integration_Result;
      Command : Editor.Commands.Command_Id;
      Message : String);

   --  Validate fake/test-owned feature command metadata and executor seams.
   --  This simulates incomplete future commands without adding them to the
   --  production Command_Id enumeration or command registry.
   procedure Validate_Command_Contract
     (Result   : in out Feature_Integration_Result;
      Contract : Feature_Command_Contract);

   --  Validate a command-like feature route. The helper records route-contract
   --  failures only; it does not invoke the Executor.
   procedure Validate_Route_Contract
     (Result   : in out Feature_Integration_Result;
      Contract : Feature_Route_Contract);

   --  Validate a future feature render projection boundary.
   procedure Validate_Render_Projection
     (Result   : in out Feature_Integration_Result;
      Contract : Feature_Render_Projection_Contract);

   --  Validate that feature persistence is explicit and does not leak into
   --  unrelated global/session domains.
   procedure Validate_Persistence_Contract
     (Result   : in out Feature_Integration_Result;
      Contract : Feature_Persistence_Contract);

   --  Validate the frozen reference Feature_Panel command/module scaffold.
   procedure Validate_Reference_Feature_Panel
     (Result : in out Feature_Integration_Result);

   --  Validate the outline content-foundation integration seam.
   procedure Validate_Outline_Content_Foundation
     (Result : in out Feature_Integration_Result);

   function Status
     (Result : Feature_Integration_Result)
      return Feature_Integration_Status;

   function Failure_Count
     (Result : Feature_Integration_Result) return Natural;

   function Summary
     (Result : Feature_Integration_Result) return String;

private
   type Feature_Integration_Result is record
      Failures : Natural := 0;
      Text     : Ada.Strings.Unbounded.Unbounded_String;
   end record;
end Editor.Feature_Integration;
