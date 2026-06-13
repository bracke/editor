with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Flow_Contract_Final_Proof_Legality is

   use type Contract_CPD.Contract_Predicate_Status;
   use type Refined.Refined_Conformance_Status;
   use type Flow_Consumer.Consumer_Status;
   use type Dataflow_Init.Dataflow_Init_Status;
   use type Cross_Final.Cross_Unit_Final_Status;
   use type Rep_Final.Final_Representation_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (Seed, Value : Natural) return Natural is
      type Hash_Value is mod 2 ** 32;
      Mixed : constant Hash_Value :=
        Hash_Value (Seed) * 16#01000193# + Hash_Value (Value) + 16#9E3779B9#;
   begin
      return Natural (Mixed mod Hash_Value (2_147_483_647));
   end Mix;

   function Kind_Slot (Kind : Flow_Contract_Proof_Context_Kind) return Natural is
   begin
      return Flow_Contract_Proof_Context_Kind'Pos (Kind) + 1;
   end Kind_Slot;

   function Status_Slot (Status : Flow_Contract_Proof_Status) return Natural is
   begin
      return Flow_Contract_Proof_Status'Pos (Status) + 1;
   end Status_Slot;

   function Contract_CPD_Legal (Status : Contract_CPD.Contract_Predicate_Status) return Boolean is
   begin
      return Status in Contract_CPD.Contract_Predicate_Legal_Precondition_Accepted .. Contract_CPD.Contract_Predicate_Legal_Refined_Depends_Accepted;
   end Contract_CPD_Legal;

   function Contract_CPD_Blocker (Status : Contract_CPD.Contract_Predicate_Status) return Boolean is
   begin
      return Status /= Contract_CPD.Contract_Predicate_Not_Checked
        and then Status /= Contract_CPD.Contract_Predicate_Indeterminate
        and then not Contract_CPD_Legal (Status);
   end Contract_CPD_Blocker;

   function Count_Blockers (Info : Flow_Contract_Proof_Context_Info) return Natural is
      Count : Natural := 0;
   begin
      if Info.Requires_Refined and then Info.Refined_Status = Refined.Refined_Conformance_Not_Checked then
         Count := Count + 1;
      elsif Info.Refined_Status /= Refined.Refined_Conformance_Not_Checked
        and then not Refined.Is_Legal (Info.Refined_Status)
      then
         Count := Count + 1;
      end if;
      if Info.Requires_Flow and then Info.Flow_Status = Flow_Consumer.Consumer_Not_Checked then
         Count := Count + 1;
      elsif Info.Flow_Status /= Flow_Consumer.Consumer_Not_Checked
        and then not Flow_Consumer.Is_Legal (Info.Flow_Status)
      then
         Count := Count + 1;
      end if;
      if Info.Requires_Dataflow_Init and then Info.Dataflow_Init_Status = Dataflow_Init.Dataflow_Init_Not_Checked then
         Count := Count + 1;
      elsif Info.Dataflow_Init_Status /= Dataflow_Init.Dataflow_Init_Not_Checked
        and then not Dataflow_Init.Is_Legal (Info.Dataflow_Init_Status)
      then
         Count := Count + 1;
      end if;
      if Info.Requires_Contract_CPD and then Info.Contract_CPD_Status = Contract_CPD.Contract_Predicate_Not_Checked then
         Count := Count + 1;
      elsif Contract_CPD_Blocker (Info.Contract_CPD_Status)
        or else Info.Contract_CPD_Status = Contract_CPD.Contract_Predicate_Indeterminate
      then
         Count := Count + 1;
      end if;
      if Info.Requires_Cross_Unit and then Info.Cross_Unit_Status = Cross_Final.Cross_Unit_Final_Not_Checked then
         Count := Count + 1;
      elsif Info.Cross_Unit_Status /= Cross_Final.Cross_Unit_Final_Not_Checked
        and then not Cross_Final.Is_Legal (Info.Cross_Unit_Status)
      then
         Count := Count + 1;
      end if;
      if Info.Requires_Representation and then Info.Representation_Status = Rep_Final.Final_Representation_Not_Checked then
         Count := Count + 1;
      elsif Info.Representation_Status /= Rep_Final.Final_Representation_Not_Checked
        and then not Rep_Final.Is_Legal (Info.Representation_Status)
      then
         Count := Count + 1;
      end if;
      if Info.Transitive_Depends_Missing_Edge then Count := Count + 1; end if;
      if Info.Transitive_Depends_Cycle then Count := Count + 1; end if;
      if Info.Transitive_Depends_Overflow then Count := Count + 1; end if;
      if Info.Dispatching_Global_Not_Refined then Count := Count + 1; end if;
      if Info.Abstract_State_Missing then Count := Count + 1; end if;
      if Info.Abstract_State_Mode_Mismatch then Count := Count + 1; end if;
      if Info.Refined_State_Missing then Count := Count + 1; end if;
      if Info.Refined_State_Extra then Count := Count + 1; end if;
      if Info.Volatile_Read_Order_Error then Count := Count + 1; end if;
      if Info.Volatile_Write_Order_Error then Count := Count + 1; end if;
      if Info.Atomic_Read_Write_Error then Count := Count + 1; end if;
      if Info.Independent_Component_Error then Count := Count + 1; end if;
      if Info.Shared_State_Task_Error then Count := Count + 1; end if;
      if Info.Source_Fingerprint /= 0 and then Info.Expected_Source_Fingerprint /= 0
        and then Info.Source_Fingerprint /= Info.Expected_Source_Fingerprint
      then
         Count := Count + 1;
      end if;
      return Count;
   end Count_Blockers;

   function Classify (Info : Flow_Contract_Proof_Context_Info) return Flow_Contract_Proof_Status is
      Blockers : constant Natural := Count_Blockers (Info);
   begin
      if Blockers > 1 then
         return Flow_Contract_Proof_Multiple_Blockers;
      end if;
      if Info.Requires_Refined and then Info.Refined_Status = Refined.Refined_Conformance_Not_Checked then
         return Flow_Contract_Proof_Missing_Refined_Conformance_Row;
      elsif Refined.Is_Global_Error (Info.Refined_Status) then
         return Flow_Contract_Proof_Refined_Global_Blocker;
      elsif Refined.Is_Depends_Error (Info.Refined_Status) then
         return Flow_Contract_Proof_Refined_Depends_Blocker;
      elsif Info.Refined_Status = Refined.Refined_Conformance_Indeterminate then
         return Flow_Contract_Proof_Indeterminate;
      elsif Info.Refined_Status /= Refined.Refined_Conformance_Not_Checked
        and then not Refined.Is_Legal (Info.Refined_Status)
      then
         return Flow_Contract_Proof_Refined_Global_Blocker;
      end if;

      if Info.Requires_Flow and then Info.Flow_Status = Flow_Consumer.Consumer_Not_Checked then
         return Flow_Contract_Proof_Missing_Flow_Consumer_Row;
      elsif Flow_Consumer.Is_Global_Error (Info.Flow_Status) then
         return Flow_Contract_Proof_Flow_Global_Blocker;
      elsif Flow_Consumer.Is_Depends_Error (Info.Flow_Status) then
         return Flow_Contract_Proof_Flow_Depends_Blocker;
      elsif Flow_Consumer.Is_Propagation_Error (Info.Flow_Status) then
         return Flow_Contract_Proof_Flow_Propagation_Blocker;
      elsif Info.Flow_Status = Flow_Consumer.Consumer_Indeterminate
        or else Info.Flow_Status = Flow_Consumer.Consumer_Refinement_Indeterminate
      then
         return Flow_Contract_Proof_Indeterminate;
      elsif Info.Flow_Status /= Flow_Consumer.Consumer_Not_Checked
        and then not Flow_Consumer.Is_Legal (Info.Flow_Status)
      then
         return Flow_Contract_Proof_Flow_Global_Blocker;
      end if;

      if Info.Requires_Dataflow_Init and then Info.Dataflow_Init_Status = Dataflow_Init.Dataflow_Init_Not_Checked then
         return Flow_Contract_Proof_Missing_Dataflow_Init_Row;
      elsif Dataflow_Init.Is_Initialization_Error (Info.Dataflow_Init_Status) then
         return Flow_Contract_Proof_Definite_Init_Blocker;
      elsif Dataflow_Init.Is_Error (Info.Dataflow_Init_Status) then
         return Flow_Contract_Proof_Dataflow_Init_Blocker;
      elsif Info.Dataflow_Init_Status = Dataflow_Init.Dataflow_Init_Indeterminate then
         return Flow_Contract_Proof_Indeterminate;
      end if;

      if Info.Requires_Contract_CPD and then Info.Contract_CPD_Status = Contract_CPD.Contract_Predicate_Not_Checked then
         return Flow_Contract_Proof_Missing_Contract_CPD_Row;
      elsif Info.Contract_CPD_Status = Contract_CPD.Contract_Predicate_Global_Blocker
        or else Info.Contract_CPD_Status = Contract_CPD.Contract_Predicate_Depends_Blocker
        or else Info.Contract_CPD_Status = Contract_CPD.Contract_Predicate_Call_Propagation_Blocker
        or else Info.Contract_CPD_Status = Contract_CPD.Contract_Predicate_Generic_Effect_Blocker
        or else Info.Contract_CPD_Status = Contract_CPD.Contract_Predicate_Tasking_Protected_Blocker
        or else Info.Contract_CPD_Status = Contract_CPD.Contract_Predicate_Linked_Dataflow_Blocker
      then
         return Flow_Contract_Proof_Contract_Dataflow_Blocker;
      elsif Contract_CPD_Blocker (Info.Contract_CPD_Status) then
         return Flow_Contract_Proof_Contract_Predicate_Blocker;
      elsif Info.Contract_CPD_Status = Contract_CPD.Contract_Predicate_Indeterminate then
         return Flow_Contract_Proof_Indeterminate;
      end if;

      if Info.Requires_Cross_Unit and then Info.Cross_Unit_Status = Cross_Final.Cross_Unit_Final_Not_Checked then
         return Flow_Contract_Proof_Missing_Cross_Unit_Final_Row;
      elsif Info.Cross_Unit_Status /= Cross_Final.Cross_Unit_Final_Not_Checked
        and then not Cross_Final.Is_Legal (Info.Cross_Unit_Status)
      then
         if Cross_Final.Is_Indeterminate (Info.Cross_Unit_Status) then
            return Flow_Contract_Proof_Indeterminate;
         else
            return Flow_Contract_Proof_Cross_Unit_Blocker;
         end if;
      end if;

      if Info.Requires_Representation and then Info.Representation_Status = Rep_Final.Final_Representation_Not_Checked then
         return Flow_Contract_Proof_Missing_Representation_Final_Row;
      elsif Info.Representation_Status /= Rep_Final.Final_Representation_Not_Checked
        and then not Rep_Final.Is_Legal (Info.Representation_Status)
      then
         if Rep_Final.Is_Indeterminate (Info.Representation_Status) then
            return Flow_Contract_Proof_Indeterminate;
         else
            return Flow_Contract_Proof_Representation_Final_Blocker;
         end if;
      end if;

      if Info.Transitive_Depends_Missing_Edge then return Flow_Contract_Proof_Transitive_Depends_Missing_Edge; end if;
      if Info.Transitive_Depends_Cycle then return Flow_Contract_Proof_Transitive_Depends_Cycle; end if;
      if Info.Transitive_Depends_Overflow then return Flow_Contract_Proof_Transitive_Depends_Overflow; end if;
      if Info.Dispatching_Global_Not_Refined then return Flow_Contract_Proof_Dispatching_Global_Not_Refined; end if;
      if Info.Abstract_State_Missing then return Flow_Contract_Proof_Abstract_State_Missing; end if;
      if Info.Abstract_State_Mode_Mismatch then return Flow_Contract_Proof_Abstract_State_Mode_Mismatch; end if;
      if Info.Refined_State_Missing then return Flow_Contract_Proof_Refined_State_Missing; end if;
      if Info.Refined_State_Extra then return Flow_Contract_Proof_Refined_State_Extra; end if;
      if Info.Volatile_Read_Order_Error then return Flow_Contract_Proof_Volatile_Read_Order_Blocker; end if;
      if Info.Volatile_Write_Order_Error then return Flow_Contract_Proof_Volatile_Write_Order_Blocker; end if;
      if Info.Atomic_Read_Write_Error then return Flow_Contract_Proof_Atomic_Read_Write_Blocker; end if;
      if Info.Independent_Component_Error then return Flow_Contract_Proof_Independent_Component_Blocker; end if;
      if Info.Shared_State_Task_Error then return Flow_Contract_Proof_Shared_State_Task_Blocker; end if;
      if Info.Source_Fingerprint /= 0 and then Info.Expected_Source_Fingerprint /= 0
        and then Info.Source_Fingerprint /= Info.Expected_Source_Fingerprint
      then
         return Flow_Contract_Proof_Source_Fingerprint_Mismatch;
      end if;

      case Info.Kind is
         when Flow_Contract_Global_Aspect => return Flow_Contract_Proof_Legal_Global_Accepted;
         when Flow_Contract_Depends_Aspect => return Flow_Contract_Proof_Legal_Depends_Accepted;
         when Flow_Contract_Refined_Global => return Flow_Contract_Proof_Legal_Refined_Global_Accepted;
         when Flow_Contract_Refined_Depends => return Flow_Contract_Proof_Legal_Refined_Depends_Accepted;
         when Flow_Contract_Transitive_Depends_Closure => return Flow_Contract_Proof_Legal_Transitive_Depends_Accepted;
         when Flow_Contract_Dispatching_Global_Refinement => return Flow_Contract_Proof_Legal_Dispatching_Global_Accepted;
         when Flow_Contract_Abstract_State => return Flow_Contract_Proof_Legal_Abstract_State_Accepted;
         when Flow_Contract_Refined_State => return Flow_Contract_Proof_Legal_Refined_State_Accepted;
         when Flow_Contract_Volatile_Object_Effect => return Flow_Contract_Proof_Legal_Volatile_Effect_Accepted;
         when Flow_Contract_Atomic_Object_Effect => return Flow_Contract_Proof_Legal_Atomic_Effect_Accepted;
         when Flow_Contract_Independent_Component_Effect => return Flow_Contract_Proof_Legal_Independent_Component_Accepted;
         when Flow_Contract_Call_Chain_Propagation => return Flow_Contract_Proof_Legal_Call_Chain_Accepted;
         when Flow_Contract_Generic_Effect_Substitution => return Flow_Contract_Proof_Legal_Generic_Effect_Accepted;
         when Flow_Contract_Task_Protected_Shared_State => return Flow_Contract_Proof_Legal_Task_Protected_State_Accepted;
         when Flow_Contract_Unknown => return Flow_Contract_Proof_Indeterminate;
      end case;
   end Classify;

   function Message_For (Status : Flow_Contract_Proof_Status) return String is
   begin
      case Status is
         when Flow_Contract_Proof_Legal_Global_Accepted => return "Global proof accepted";
         when Flow_Contract_Proof_Legal_Depends_Accepted => return "Depends proof accepted";
         when Flow_Contract_Proof_Legal_Refined_Global_Accepted => return "Refined_Global proof accepted";
         when Flow_Contract_Proof_Legal_Refined_Depends_Accepted => return "Refined_Depends proof accepted";
         when Flow_Contract_Proof_Legal_Transitive_Depends_Accepted => return "transitive Depends proof accepted";
         when Flow_Contract_Proof_Legal_Dispatching_Global_Accepted => return "dispatching Global refinement accepted";
         when Flow_Contract_Proof_Legal_Abstract_State_Accepted => return "abstract state proof accepted";
         when Flow_Contract_Proof_Legal_Refined_State_Accepted => return "refined state proof accepted";
         when Flow_Contract_Proof_Legal_Volatile_Effect_Accepted => return "volatile effect proof accepted";
         when Flow_Contract_Proof_Legal_Atomic_Effect_Accepted => return "atomic effect proof accepted";
         when Flow_Contract_Proof_Legal_Independent_Component_Accepted => return "independent component effect proof accepted";
         when Flow_Contract_Proof_Legal_Call_Chain_Accepted => return "call-chain flow proof accepted";
         when Flow_Contract_Proof_Legal_Generic_Effect_Accepted => return "generic effect proof accepted";
         when Flow_Contract_Proof_Legal_Task_Protected_State_Accepted => return "task/protected shared-state proof accepted";
         when Flow_Contract_Proof_Missing_Refined_Conformance_Row => return "refined conformance evidence is missing";
         when Flow_Contract_Proof_Refined_Global_Blocker => return "Refined_Global conformance blocks final proof";
         when Flow_Contract_Proof_Refined_Depends_Blocker => return "Refined_Depends conformance blocks final proof";
         when Flow_Contract_Proof_Missing_Flow_Consumer_Row => return "flow-refinement consumer evidence is missing";
         when Flow_Contract_Proof_Flow_Global_Blocker => return "Global flow consumer blocks final proof";
         when Flow_Contract_Proof_Flow_Depends_Blocker => return "Depends flow consumer blocks final proof";
         when Flow_Contract_Proof_Flow_Propagation_Blocker => return "call propagation flow consumer blocks final proof";
         when Flow_Contract_Proof_Missing_Dataflow_Init_Row => return "dataflow initialization evidence is missing";
         when Flow_Contract_Proof_Dataflow_Init_Blocker => return "dataflow initialization consumer blocks final proof";
         when Flow_Contract_Proof_Definite_Init_Blocker => return "definite initialization blocks final flow proof";
         when Flow_Contract_Proof_Missing_Contract_CPD_Row => return "contract predicate/dataflow evidence is missing";
         when Flow_Contract_Proof_Contract_Predicate_Blocker => return "contract predicate evidence blocks final proof";
         when Flow_Contract_Proof_Contract_Dataflow_Blocker => return "contract dataflow evidence blocks final proof";
         when Flow_Contract_Proof_Missing_Cross_Unit_Final_Row => return "cross-unit final closure evidence is missing";
         when Flow_Contract_Proof_Cross_Unit_Blocker => return "cross-unit final closure blocks final proof";
         when Flow_Contract_Proof_Missing_Representation_Final_Row => return "representation final evidence is missing";
         when Flow_Contract_Proof_Representation_Final_Blocker => return "representation final evidence blocks final proof";
         when Flow_Contract_Proof_Transitive_Depends_Missing_Edge => return "transitive Depends edge is missing";
         when Flow_Contract_Proof_Transitive_Depends_Cycle => return "transitive Depends cycle blocks proof";
         when Flow_Contract_Proof_Transitive_Depends_Overflow => return "transitive Depends closure overflow";
         when Flow_Contract_Proof_Dispatching_Global_Not_Refined => return "dispatching Global effect is not refined";
         when Flow_Contract_Proof_Abstract_State_Missing => return "abstract state evidence is missing";
         when Flow_Contract_Proof_Abstract_State_Mode_Mismatch => return "abstract state mode mismatch";
         when Flow_Contract_Proof_Refined_State_Missing => return "refined state evidence is missing";
         when Flow_Contract_Proof_Refined_State_Extra => return "extra refined state item";
         when Flow_Contract_Proof_Volatile_Read_Order_Blocker => return "volatile read ordering blocks proof";
         when Flow_Contract_Proof_Volatile_Write_Order_Blocker => return "volatile write ordering blocks proof";
         when Flow_Contract_Proof_Atomic_Read_Write_Blocker => return "atomic read/write effect blocks proof";
         when Flow_Contract_Proof_Independent_Component_Blocker => return "independent component effect blocks proof";
         when Flow_Contract_Proof_Shared_State_Task_Blocker => return "shared state task/protected effect blocks proof";
         when Flow_Contract_Proof_Source_Fingerprint_Mismatch => return "flow/contract source fingerprint mismatch";
         when Flow_Contract_Proof_Multiple_Blockers => return "multiple final flow/contract proof blockers preserved";
         when Flow_Contract_Proof_Indeterminate => return "final flow/contract proof is indeterminate";
         when Flow_Contract_Proof_Not_Checked => return "final flow/contract proof was not checked";
      end case;
   end Message_For;

   function Detail_For (Info : Flow_Contract_Proof_Context_Info) return String is
   begin
      return "subprogram=" & To_String (Info.Subprogram_Name)
        & "; object=" & To_String (Info.Object_Name)
        & "; source=" & To_String (Info.Source_Name)
        & "; target=" & To_String (Info.Target_Name);
   end Detail_For;

   procedure Clear (Model : in out Flow_Contract_Proof_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context (Model : in out Flow_Contract_Proof_Context_Model; Info : Flow_Contract_Proof_Context_Info) is
   begin
      Model.Contexts.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Kind_Slot (Info.Kind));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Node));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Source_Fingerprint);
   end Add_Context;

   function Context_Count (Model : Flow_Contract_Proof_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At (Model : Flow_Contract_Proof_Context_Model; Index : Positive) return Flow_Contract_Proof_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Flow_Contract_Proof_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Build (Contexts : Flow_Contract_Proof_Context_Model) return Flow_Contract_Proof_Model is
      Model : Flow_Contract_Proof_Model;
   begin
      for I in 1 .. Context_Count (Contexts) loop
         declare
            C : constant Flow_Contract_Proof_Context_Info := Context_At (Contexts, I);
            Status : constant Flow_Contract_Proof_Status := Classify (C);
            Row : Flow_Contract_Proof_Info;
         begin
            Row.Id := Flow_Contract_Proof_Row_Id (I);
            Row.Context := C.Id;
            Row.Kind := C.Kind;
            Row.Status := Status;
            Row.Node := C.Node;
            Row.Subprogram_Name := C.Subprogram_Name;
            Row.Object_Name := C.Object_Name;
            Row.Source_Name := C.Source_Name;
            Row.Target_Name := C.Target_Name;
            Row.Message := To_Unbounded_String (Message_For (Status));
            Row.Detail := To_Unbounded_String (Detail_For (C));
            Row.Blocker_Count := Count_Blockers (C);
            Row.Source_Fingerprint := C.Source_Fingerprint;
            Row.Start_Line := C.Start_Line;
            Row.Start_Column := C.Start_Column;
            Row.End_Line := C.End_Line;
            Row.End_Column := C.End_Column;
            Row.Fingerprint := Mix (Natural (Row.Id), Status_Slot (Status));
            Row.Fingerprint := Mix (Row.Fingerprint, Kind_Slot (Row.Kind));
            Row.Fingerprint := Mix (Row.Fingerprint, Natural (Row.Node));
            Row.Fingerprint := Mix (Row.Fingerprint, Row.Source_Fingerprint);
            Model.Items.Append (Row);
            Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Row.Fingerprint);
            if Is_Legal (Status) then Model.Legal_Total := Model.Legal_Total + 1; else Model.Error_Total := Model.Error_Total + 1; end if;
            if Is_Refined_Error (Status) then Model.Refined_Error_Total := Model.Refined_Error_Total + 1; end if;
            if Is_Flow_Error (Status) then Model.Flow_Error_Total := Model.Flow_Error_Total + 1; end if;
            if Is_Dataflow_Error (Status) then Model.Dataflow_Error_Total := Model.Dataflow_Error_Total + 1; end if;
            if Is_Contract_Error (Status) then Model.Contract_Error_Total := Model.Contract_Error_Total + 1; end if;
            if Is_State_Effect_Error (Status) then Model.State_Effect_Error_Total := Model.State_Effect_Error_Total + 1; end if;
            if Is_Indeterminate (Status) then Model.Indeterminate_Total := Model.Indeterminate_Total + 1; end if;
         end;
      end loop;
      if Model.Result_Fingerprint = 0 and then Row_Count (Model) > 0 then
         Model.Result_Fingerprint := Row_Count (Model) * 1192;
      end if;
      return Model;
   end Build;

   function Row_Count (Model : Flow_Contract_Proof_Model) return Natural is begin return Natural (Model.Items.Length); end Row_Count;
   function Row_At (Model : Flow_Contract_Proof_Model; Index : Positive) return Flow_Contract_Proof_Info is begin return Model.Items.Element (Index); end Row_At;

   function First_For_Node (Model : Flow_Contract_Proof_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Flow_Contract_Proof_Info is
   begin
      for I in 1 .. Row_Count (Model) loop
         if Row_At (Model, I).Node = Node then return Row_At (Model, I); end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status (Model : Flow_Contract_Proof_Model; Status : Flow_Contract_Proof_Status) return Flow_Contract_Proof_Set is
      Result : Flow_Contract_Proof_Set;
   begin
      for I in 1 .. Row_Count (Model) loop
         if Row_At (Model, I).Status = Status then
            Result.Items.Append (Row_At (Model, I));
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, Row_At (Model, I).Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Status;

   function Rows_For_Kind (Model : Flow_Contract_Proof_Model; Kind : Flow_Contract_Proof_Context_Kind) return Flow_Contract_Proof_Set is
      Result : Flow_Contract_Proof_Set;
   begin
      for I in 1 .. Row_Count (Model) loop
         if Row_At (Model, I).Kind = Kind then
            Result.Items.Append (Row_At (Model, I));
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, Row_At (Model, I).Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Kind;

   function Set_Count (Set : Flow_Contract_Proof_Set) return Natural is begin return Natural (Set.Items.Length); end Set_Count;
   function Set_At (Set : Flow_Contract_Proof_Set; Index : Positive) return Flow_Contract_Proof_Info is begin return Set.Items.Element (Index); end Set_At;

   function Count_Status (Model : Flow_Contract_Proof_Model; Status : Flow_Contract_Proof_Status) return Natural is
      Count : Natural := 0;
   begin
      for I in 1 .. Row_Count (Model) loop
         if Row_At (Model, I).Status = Status then Count := Count + 1; end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind (Model : Flow_Contract_Proof_Model; Kind : Flow_Contract_Proof_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for I in 1 .. Row_Count (Model) loop
         if Row_At (Model, I).Kind = Kind then Count := Count + 1; end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : Flow_Contract_Proof_Model) return Natural is begin return Model.Legal_Total; end Legal_Count;
   function Error_Count (Model : Flow_Contract_Proof_Model) return Natural is begin return Model.Error_Total; end Error_Count;
   function Refined_Error_Count (Model : Flow_Contract_Proof_Model) return Natural is begin return Model.Refined_Error_Total; end Refined_Error_Count;
   function Flow_Error_Count (Model : Flow_Contract_Proof_Model) return Natural is begin return Model.Flow_Error_Total; end Flow_Error_Count;
   function Dataflow_Error_Count (Model : Flow_Contract_Proof_Model) return Natural is begin return Model.Dataflow_Error_Total; end Dataflow_Error_Count;
   function Contract_Error_Count (Model : Flow_Contract_Proof_Model) return Natural is begin return Model.Contract_Error_Total; end Contract_Error_Count;
   function State_Effect_Error_Count (Model : Flow_Contract_Proof_Model) return Natural is begin return Model.State_Effect_Error_Total; end State_Effect_Error_Count;
   function Indeterminate_Count (Model : Flow_Contract_Proof_Model) return Natural is begin return Model.Indeterminate_Total; end Indeterminate_Count;
   function Fingerprint (Model : Flow_Contract_Proof_Model) return Natural is begin return Model.Result_Fingerprint; end Fingerprint;

   function Is_Legal (Status : Flow_Contract_Proof_Status) return Boolean is
   begin
      return Status in Flow_Contract_Proof_Legal_Global_Accepted .. Flow_Contract_Proof_Legal_Task_Protected_State_Accepted;
   end Is_Legal;

   function Is_Refined_Error (Status : Flow_Contract_Proof_Status) return Boolean is
   begin
      return Status in Flow_Contract_Proof_Missing_Refined_Conformance_Row .. Flow_Contract_Proof_Refined_Depends_Blocker;
   end Is_Refined_Error;

   function Is_Flow_Error (Status : Flow_Contract_Proof_Status) return Boolean is
   begin
      return Status in Flow_Contract_Proof_Missing_Flow_Consumer_Row .. Flow_Contract_Proof_Flow_Propagation_Blocker;
   end Is_Flow_Error;

   function Is_Dataflow_Error (Status : Flow_Contract_Proof_Status) return Boolean is
   begin
      return Status in Flow_Contract_Proof_Missing_Dataflow_Init_Row .. Flow_Contract_Proof_Definite_Init_Blocker;
   end Is_Dataflow_Error;

   function Is_Contract_Error (Status : Flow_Contract_Proof_Status) return Boolean is
   begin
      return Status in Flow_Contract_Proof_Missing_Contract_CPD_Row .. Flow_Contract_Proof_Representation_Final_Blocker;
   end Is_Contract_Error;

   function Is_State_Effect_Error (Status : Flow_Contract_Proof_Status) return Boolean is
   begin
      return Status in Flow_Contract_Proof_Transitive_Depends_Missing_Edge .. Flow_Contract_Proof_Source_Fingerprint_Mismatch;
   end Is_State_Effect_Error;

   function Is_Indeterminate (Status : Flow_Contract_Proof_Status) return Boolean is
   begin
      return Status = Flow_Contract_Proof_Indeterminate;
   end Is_Indeterminate;

   function Has_Error (Info : Flow_Contract_Proof_Info) return Boolean is
   begin
      return not Is_Legal (Info.Status) and then Info.Status /= Flow_Contract_Proof_Not_Checked;
   end Has_Error;

end Editor.Ada_Flow_Contract_Final_Proof_Legality;
