with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_AST_Coverage_Repair_Gate_Application is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Audit.Ada_Construct_Kind;
   use type Enforce.Enforcement_Status;
   use type Enforce.Widened_Legality_Engine;
   use type Repair.Repair_Status;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 131) + B + 23) mod 2_147_483_647;
   end Mix;

   function Clears_Gate (Status : Application_Status) return Boolean is
   begin
      return Status in
        Application_Already_Confident |
        Application_Repair_Clears_Parser_AST_Blocker |
        Application_Repair_Clears_Metadata_Blocker |
        Application_Repair_Clears_Consumer_Blocker |
        Application_Repair_Clears_Suppressed_Legal |
        Application_Repair_Clears_Suppressed_Derived |
        Application_Repair_Clears_Unsafe_Blocker;
   end Clears_Gate;

   function Classify
     (Enforcement_Status : Enforce.Enforcement_Status;
      Repair_Status      : Repair.Repair_Status;
      Repair_Kind        : Repair.Repair_Kind) return Application_Status is
      Repaired : constant Boolean := Repair.Is_Repaired (Repair_Status);
   begin
      if Enforcement_Status = Enforce.Enforcement_Confident_Result_Allowed then
         return Application_Already_Confident;
      elsif Enforcement_Status = Enforce.Enforcement_Original_Error_Preserved then
         return Application_Original_Error_Preserved;
      elsif Enforcement_Status = Enforce.Enforcement_Cross_Unit_Closure_Required then
         return Application_Cross_Unit_Still_Required;
      end if;

      if Repair_Status = Repair.Repair_Not_Checked then
         return Application_Repair_Missing;
      elsif Repair_Status in Repair.Repair_Indeterminate | Repair.Repair_Inconsistent_Repair then
         return Application_Repair_Partial;
      elsif not Repaired then
         return Application_Repair_Missing;
      end if;

      case Enforcement_Status is
         when Enforce.Enforcement_Parser_AST_Blocker =>
            if Repair_Kind in Repair.Repair_Parser_Node |
                              Repair.Repair_Structural_AST |
                              Repair.Repair_Source_Span |
                              Repair.Repair_Token_Only_Replacement |
                              Repair.Repair_Degradation_Replacement |
                              Repair.Repair_Combined_Construct_Coverage
            then
               return Application_Repair_Clears_Parser_AST_Blocker;
            else
               return Application_Repair_Mismatch;
            end if;
         when Enforce.Enforcement_Metadata_Blocker =>
            if Repair_Kind in Repair.Repair_Name_Binding_Metadata |
                              Repair.Repair_Type_Metadata |
                              Repair.Repair_Staticness_Metadata |
                              Repair.Repair_Contract_Metadata |
                              Repair.Repair_Flow_Metadata |
                              Repair.Repair_Representation_Metadata |
                              Repair.Repair_Cross_Unit_Metadata |
                              Repair.Repair_Combined_Construct_Coverage
            then
               return Application_Repair_Clears_Metadata_Blocker;
            else
               return Application_Repair_Mismatch;
            end if;
         when Enforce.Enforcement_Consumer_Integration_Blocker =>
            if Repair_Kind in Repair.Repair_Semantic_Consumer |
                              Repair.Repair_Consumer_Integration |
                              Repair.Repair_Combined_Construct_Coverage
            then
               return Application_Repair_Clears_Consumer_Blocker;
            else
               return Application_Repair_Mismatch;
            end if;
         when Enforce.Enforcement_Legal_Result_Suppressed =>
            return Application_Repair_Clears_Suppressed_Legal;
         when Enforce.Enforcement_Derived_Result_Suppressed =>
            return Application_Repair_Clears_Suppressed_Derived;
         when Enforce.Enforcement_Unsafe_Result_Blocked =>
            return Application_Repair_Clears_Unsafe_Blocker;
         when Enforce.Enforcement_Degraded_To_Indeterminate =>
            return Application_Repair_Indeterminate;
         when others =>
            return Application_Enforcement_Still_Blocking;
      end case;
   end Classify;

   function Message_For (Status : Application_Status) return String is
   begin
      case Status is
         when Application_Already_Confident => return "semantic result is already confident";
         when Application_Repair_Clears_Parser_AST_Blocker => return "coverage repair clears parser/AST blocker";
         when Application_Repair_Clears_Metadata_Blocker => return "coverage repair clears semantic metadata blocker";
         when Application_Repair_Clears_Consumer_Blocker => return "coverage repair clears semantic consumer blocker";
         when Application_Repair_Clears_Suppressed_Legal => return "coverage repair restores suppressed legal result";
         when Application_Repair_Clears_Suppressed_Derived => return "coverage repair restores suppressed derived result";
         when Application_Repair_Clears_Unsafe_Blocker => return "coverage repair clears unsafe-result blocker";
         when Application_Cross_Unit_Still_Required => return "cross-unit closure is still required";
         when Application_Original_Error_Preserved => return "original semantic error is preserved";
         when Application_Repair_Missing => return "coverage repair is missing";
         when Application_Repair_Partial => return "coverage repair is partial or indeterminate";
         when Application_Repair_Indeterminate => return "semantic result remains indeterminate after repair";
         when Application_Repair_Mismatch => return "coverage repair kind does not match gate blocker";
         when Application_Enforcement_Still_Blocking => return "coverage enforcement remains blocking";
         when Application_Not_Checked => return "coverage repair application not checked";
      end case;
   end Message_For;

   function Make_Row (Context : Application_Context_Info) return Application_Info is
      Status : constant Application_Status :=
        Classify (Context.Enforcement_Status,
                  Context.Repair_Status,
                  Context.Repair_Kind);
      Row : Application_Info;
      FP  : Natural := Context.Source_Fingerprint;
   begin
      FP := Mix (FP, Application_Status'Pos (Status));
      FP := Mix (FP, Enforce.Enforcement_Status'Pos (Context.Enforcement_Status));
      FP := Mix (FP, Repair.Repair_Status'Pos (Context.Repair_Status));
      FP := Mix (FP, Repair.Repair_Kind'Pos (Context.Repair_Kind));
      FP := Mix (FP, Gates.Semantic_Conclusion_Kind'Pos (Context.Conclusion));
      FP := Mix (FP, Audit.Ada_Construct_Kind'Pos (Context.Construct));
      FP := Mix (FP, Natural (Context.Node));

      Row.Id := Context.Id;
      Row.Repair_Id := Context.Repair_Id;
      Row.Enforcement_Id := Context.Enforcement_Id;
      Row.Engine := Context.Engine;
      Row.Status := Status;
      Row.Enforcement_Status := Context.Enforcement_Status;
      Row.Repair_Status := Context.Repair_Status;
      Row.Repair_Kind := Context.Repair_Kind;
      Row.Conclusion := Context.Conclusion;
      Row.Construct := Context.Construct;
      Row.Consumer := Context.Consumer;
      Row.Original_State := Context.Original_State;
      Row.Gate_Status := Context.Gate_Status;
      Row.Gate_Action := Context.Gate_Action;
      Row.Node := Context.Node;
      Row.Parent_Node := Context.Parent_Node;
      Row.Semantic_Row_Id := Context.Semantic_Row_Id;
      Row.Construct_Name := Context.Construct_Name;
      Row.Normalized_Name := Context.Normalized_Name;
      Row.Message := To_Unbounded_String (Message_For (Status));
      Row.Detail := To_Unbounded_String
        ("repair=" & To_String (Context.Repair_Message) &
         "; enforcement=" & To_String (Context.Enforcement_Message));
      Row.Source_Fingerprint := Context.Source_Fingerprint;
      Row.Start_Line := Context.Start_Line;
      Row.Start_Column := Context.Start_Column;
      Row.End_Line := Context.End_Line;
      Row.End_Column := Context.End_Column;
      Row.Fingerprint := FP;
      return Row;
   end Make_Row;

   function Has_Blocker (Info : Application_Info) return Boolean is
   begin
      return not Clears_Gate (Info.Status)
        or else Info.Status = Application_Original_Error_Preserved;
   end Has_Blocker;

   procedure Clear (Model : in out Application_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model   : in out Application_Context_Model;
      Context : Application_Context_Info) is
   begin
      Model.Items.Append (Context);
      Model.Fingerprint := Mix (Model.Fingerprint, Context.Source_Fingerprint);
   end Add_Context;

   procedure Add_From_Repair_And_Enforcement
     (Model       : in out Application_Context_Model;
      Repair_Row  : Repair.Repair_Info;
      Enforced_Row : Enforce.Enforcement_Info) is
      C : Application_Context_Info;
   begin
      C.Id := Application_Row_Id (Natural (Enforced_Row.Id));
      C.Repair_Id := Repair_Row.Id;
      C.Enforcement_Id := Enforced_Row.Id;
      C.Engine := Enforced_Row.Engine;
      C.Enforcement_Status := Enforced_Row.Status;
      C.Repair_Status := Repair_Row.Status;
      C.Repair_Kind := Repair_Row.Kind;
      C.Conclusion := Enforced_Row.Conclusion;
      C.Construct := Enforced_Row.Construct;
      C.Consumer := Enforced_Row.Consumer;
      C.Original_State := Enforced_Row.Original_State;
      C.Gate_Status := Enforced_Row.Gate_Status;
      C.Gate_Action := Enforced_Row.Gate_Action;
      C.Node := Enforced_Row.Node;
      C.Parent_Node := Enforced_Row.Parent_Node;
      C.Semantic_Row_Id := Enforced_Row.Semantic_Row_Id;
      C.Construct_Name := Enforced_Row.Construct_Name;
      C.Normalized_Name := Enforced_Row.Normalized_Name;
      C.Repair_Message := Repair_Row.Message;
      C.Enforcement_Message := Enforced_Row.Message;
      C.Source_Fingerprint := Mix (Repair_Row.Fingerprint, Enforced_Row.Fingerprint);
      C.Start_Line := Enforced_Row.Start_Line;
      C.Start_Column := Enforced_Row.Start_Column;
      C.End_Line := Enforced_Row.End_Line;
      C.End_Column := Enforced_Row.End_Column;
      Add_Context (Model, C);
   end Add_From_Repair_And_Enforcement;

   function Build (Contexts : Application_Context_Model) return Application_Model is
      Result : Application_Model;
      Row    : Application_Info;
   begin
      for I in 1 .. Natural (Contexts.Items.Length) loop
         Row := Make_Row (Contexts.Items.Element (I));
         Result.Items.Append (Row);
         Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
         if Clears_Gate (Row.Status) then
            Result.Cleared_Total := Result.Cleared_Total + 1;
         else
            Result.Still_Blocking_Total := Result.Still_Blocking_Total + 1;
         end if;
         if Row.Status = Application_Repair_Missing then
            Result.Missing_Repair_Total := Result.Missing_Repair_Total + 1;
         end if;
         if Row.Status in Application_Repair_Partial | Application_Repair_Indeterminate then
            Result.Partial_Repair_Total := Result.Partial_Repair_Total + 1;
         end if;
         if Row.Status = Application_Cross_Unit_Still_Required then
            Result.Cross_Unit_Total := Result.Cross_Unit_Total + 1;
         end if;
         if Row.Status = Application_Original_Error_Preserved then
            Result.Original_Error_Total := Result.Original_Error_Total + 1;
         end if;
      end loop;
      return Result;
   end Build;

   function Build_From_Repair_And_Enforcement
     (Repairs      : Repair.Repair_Model;
      Enforcement  : Enforce.Enforcement_Model) return Application_Model is
      Contexts : Application_Context_Model;
      E        : Enforce.Enforcement_Info;
      R        : Repair.Repair_Info;
   begin
      for I in 1 .. Enforce.Row_Count (Enforcement) loop
         E := Enforce.Row_At (Enforcement, I);
         R := Repair.First_For_Node (Repairs, E.Node);
         Add_From_Repair_And_Enforcement (Contexts, R, E);
      end loop;
      return Build (Contexts);
   end Build_From_Repair_And_Enforcement;

   function Row_Count (Model : Application_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Row_Count;

   function Row_At
     (Model : Application_Model;
      Index : Positive) return Application_Info is
   begin
      return Model.Items.Element (Index);
   end Row_At;

   function First_For_Node
     (Model : Application_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Application_Info is
   begin
      for Row of Model.Items loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Application_Model;
      Status : Application_Status) return Application_Set is
      Set : Application_Set;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then
            Set.Items.Append (Row);
            Set.Fingerprint := Mix (Set.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Set;
   end Rows_For_Status;

   function Rows_For_Engine
     (Model  : Application_Model;
      Engine : Enforce.Widened_Legality_Engine) return Application_Set is
      Set : Application_Set;
   begin
      for Row of Model.Items loop
         if Row.Engine = Engine then
            Set.Items.Append (Row);
            Set.Fingerprint := Mix (Set.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Set;
   end Rows_For_Engine;

   function Rows_For_Construct
     (Model     : Application_Model;
      Construct : Audit.Ada_Construct_Kind) return Application_Set is
      Set : Application_Set;
   begin
      for Row of Model.Items loop
         if Row.Construct = Construct then
            Set.Items.Append (Row);
            Set.Fingerprint := Mix (Set.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Set;
   end Rows_For_Construct;

   function Set_Count (Set : Application_Set) return Natural is
   begin
      return Natural (Set.Items.Length);
   end Set_Count;

   function Set_At
     (Set   : Application_Set;
      Index : Positive) return Application_Info is
   begin
      return Set.Items.Element (Index);
   end Set_At;

   function Count_Status
     (Model  : Application_Model;
      Status : Application_Status) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Engine
     (Model  : Application_Model;
      Engine : Enforce.Widened_Legality_Engine) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Engine = Engine then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Engine;

   function Count_Construct
     (Model     : Application_Model;
      Construct : Audit.Ada_Construct_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Construct = Construct then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Construct;

   function Cleared_Count (Model : Application_Model) return Natural is
   begin
      return Model.Cleared_Total;
   end Cleared_Count;

   function Still_Blocking_Count (Model : Application_Model) return Natural is
   begin
      return Model.Still_Blocking_Total;
   end Still_Blocking_Count;

   function Missing_Repair_Count (Model : Application_Model) return Natural is
   begin
      return Model.Missing_Repair_Total;
   end Missing_Repair_Count;

   function Partial_Repair_Count (Model : Application_Model) return Natural is
   begin
      return Model.Partial_Repair_Total;
   end Partial_Repair_Count;

   function Cross_Unit_Required_Count (Model : Application_Model) return Natural is
   begin
      return Model.Cross_Unit_Total;
   end Cross_Unit_Required_Count;

   function Original_Error_Count (Model : Application_Model) return Natural is
   begin
      return Model.Original_Error_Total;
   end Original_Error_Count;

   function Fingerprint (Model : Application_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_AST_Coverage_Repair_Gate_Application;
