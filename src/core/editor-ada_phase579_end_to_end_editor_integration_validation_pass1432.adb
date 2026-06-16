with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Phase579_End_To_End_Editor_Integration_Validation_Pass1432 is

   pragma Suppress (Overflow_Check);

   procedure Add_Row (Input : in out Integration_Input; Row : Integration_Row) is
   begin
      Input.Rows.Append (Row);
   end Add_Row;

   function Class_For_Status (Status : Integration_Status) return Integration_Result_Class is
   begin
      case Status is
         when Status_Validated =>
            return Class_Validated;
         when Status_Rejected_Rendering_Side_Parsing
            | Status_Rejected_Save_Reload_During_Analysis
            | Status_Rejected_Dirty_State_Mutation
            | Status_Rejected_Command_Surface_Mutation_Leak
            | Status_Rejected_Keybinding_Mutation_Leak
            | Status_Rejected_Workspace_Mutation_Leak
            | Status_Rejected_Render_Mutation_Leak
            | Status_Rejected_Stale_Snapshot_Accepted
            | Status_Rejected_Unbounded_Work
            | Status_Rejected_Consumer_Disagreement
            | Status_Rejected_Reopened_Remaining_Gap
            | Status_Rejected_Stale_Integration_Evidence =>
            return Class_Rejected;
         when Status_Indeterminate_Missing_Evidence =>
            return Class_Indeterminate;
         when Status_Not_Checked =>
            return Class_Unknown;
      end case;
   end Class_For_Status;

   function Has_Evidence (Row : Integration_Row) return Boolean is
   begin
      return Row.Evidence_Present
        and then Row.Surface /= Surface_Unknown
        and then Length (Row.Scenario_Name) > 0
        and then Row.Snapshot_Owned_Analysis;
   end Has_Evidence;

   function Fingerprints_Fresh (Row : Integration_Row) return Boolean is
   begin
      return Row.Source_Fingerprint = Row.Expected_Source_Fingerprint
        and then Row.Snapshot_Fingerprint = Row.Expected_Snapshot_Fingerprint
        and then Row.Consumer_Fingerprint = Row.Expected_Consumer_Fingerprint
        and then Row.Workflow_Fingerprint = Row.Expected_Workflow_Fingerprint;
   end Fingerprints_Fresh;

   function Evaluate (Row : Integration_Row) return Integration_Status is
   begin
      if not Has_Evidence (Row) then
         return Status_Indeterminate_Missing_Evidence;
      elsif not Fingerprints_Fresh (Row) then
         return Status_Rejected_Stale_Integration_Evidence;
      elsif Row.Rendering_Side_Parsing then
         return Status_Rejected_Rendering_Side_Parsing;
      elsif Row.Save_Reload_During_Analysis then
         return Status_Rejected_Save_Reload_During_Analysis;
      elsif Row.Dirty_State_Mutated then
         return Status_Rejected_Dirty_State_Mutation;
      elsif Row.Command_Surface_Mutated then
         return Status_Rejected_Command_Surface_Mutation_Leak;
      elsif Row.Keybinding_Mutated then
         return Status_Rejected_Keybinding_Mutation_Leak;
      elsif Row.Workspace_Mutated_By_Analysis then
         return Status_Rejected_Workspace_Mutation_Leak;
      elsif Row.Render_Model_Mutated_By_Analysis then
         return Status_Rejected_Render_Mutation_Leak;
      elsif Row.Stale_Snapshot_Accepted then
         return Status_Rejected_Stale_Snapshot_Accepted;
      elsif not Row.Bounded_Work then
         return Status_Rejected_Unbounded_Work;
      elsif not Row.Consumers_Agree then
         return Status_Rejected_Consumer_Disagreement;
      elsif Row.Reopened_Remaining_Gap then
         return Status_Rejected_Reopened_Remaining_Gap;
      else
         return Status_Validated;
      end if;
   end Evaluate;

   function Result_Fingerprint_For
     (Row : Integration_Row; Status : Integration_Status) return Natural is
   begin
      return Row.Id * 137
        + Integration_Surface'Pos (Row.Surface) * 71
        + Integration_Status'Pos (Status) * 47
        + Row.Source_Fingerprint
        + Row.Snapshot_Fingerprint
        + Row.Consumer_Fingerprint
        + Row.Workflow_Fingerprint;
   end Result_Fingerprint_For;

   procedure Tally (Model : in out Integration_Model; Feed_Item : Integration_Entry) is
   begin
      case Feed_Item.Status is
         when Status_Validated =>
            Model.Validated_Count := Model.Validated_Count + 1;
         when Status_Rejected_Rendering_Side_Parsing
            | Status_Rejected_Save_Reload_During_Analysis
            | Status_Rejected_Dirty_State_Mutation
            | Status_Rejected_Command_Surface_Mutation_Leak
            | Status_Rejected_Keybinding_Mutation_Leak
            | Status_Rejected_Workspace_Mutation_Leak
            | Status_Rejected_Render_Mutation_Leak
            | Status_Rejected_Stale_Snapshot_Accepted
            | Status_Rejected_Unbounded_Work
            | Status_Rejected_Consumer_Disagreement
            | Status_Rejected_Reopened_Remaining_Gap
            | Status_Rejected_Stale_Integration_Evidence =>
            Model.Rejected_Count := Model.Rejected_Count + 1;
         when Status_Indeterminate_Missing_Evidence =>
            Model.Indeterminate_Count := Model.Indeterminate_Count + 1;
         when Status_Not_Checked =>
            null;
      end case;
   end Tally;

   function Build (Input : Integration_Input) return Integration_Model is
      Model : Integration_Model;
      Status : Integration_Status;
      Feed_Item : Integration_Entry;
   begin
      for Row of Input.Rows loop
         Status := Evaluate (Row);
         Feed_Item.Id := Row.Id;
         Feed_Item.Surface := Row.Surface;
         Feed_Item.Status := Status;
         Feed_Item.Result_Class := Class_For_Status (Status);
         Feed_Item.Result_Fingerprint := Result_Fingerprint_For (Row, Status);
         Model.Entries.Append (Feed_Item);
         Model.Total_Rows := Model.Total_Rows + 1;
         Model.Integration_Fingerprint :=
           Model.Integration_Fingerprint + Feed_Item.Result_Fingerprint;
         Tally (Model, Feed_Item);
      end loop;
      return Model;
   end Build;

   function Result_For (Model : Integration_Model; Id : Natural) return Integration_Entry is
   begin
      for Feed_Item of Model.Entries loop
         if Feed_Item.Id = Id then
            return Feed_Item;
         end if;
      end loop;
      return (Id => Id,
              Surface => Surface_Unknown,
              Status => Status_Not_Checked,
              Result_Class => Class_Unknown,
              Result_Fingerprint => 0);
   end Result_For;

   function End_To_End_Integration_Achieved (Model : Integration_Model) return Boolean is
   begin
      return Model.Total_Rows >= 10
        and then Model.Validated_Count = Model.Total_Rows
        and then Model.Rejected_Count = 0
        and then Model.Indeterminate_Count = 0
        and then Model.Integration_Fingerprint > 0;
   end End_To_End_Integration_Achieved;

end Editor.Ada_Phase579_End_To_End_Editor_Integration_Validation_Pass1432;
