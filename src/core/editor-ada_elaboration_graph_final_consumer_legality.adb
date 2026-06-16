with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Elaboration_Graph_Final_Consumer_Legality is

   pragma Suppress (Overflow_Check);

   use type Access_Final.Master_Scope_Final_Row_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Elab_CPD.Elaboration_Contract_Predicate_Row_Id;
   use type Generic_Backmap.Generic_Backmap_Row_Id;
   use type Overload_Edge.Overload_Type_Edge_Row_Id;
   use type Representation_CPD.Representation_Tasking_CPD_Row_Id;
   use type Tasking_CPD.Tasking_Contract_Predicate_Row_Id;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 131) + B + 17) mod 2_147_483_647;
   end Mix;

   function Has (S, Pattern : String) return Boolean is
   begin
      return Ada.Strings.Fixed.Index (S, Pattern) /= 0;
   end Has;

   function Legal_Status_For_Kind
     (Kind : Final_Elaboration_Context_Kind) return Final_Elaboration_Status is
   begin
      case Kind is
         when Final_Elaboration_Direct_Call |
              Final_Elaboration_Indirect_Call |
              Final_Elaboration_Dispatching_Call =>
            return Final_Elaboration_Legal_Call_Accepted;
         when Final_Elaboration_Default_Expression =>
            return Final_Elaboration_Legal_Default_Expression_Accepted;
         when Final_Elaboration_Aspect_Expression =>
            return Final_Elaboration_Legal_Aspect_Expression_Accepted;
         when Final_Elaboration_Representation_Item =>
            return Final_Elaboration_Legal_Representation_Item_Accepted;
         when Final_Elaboration_Task_Activation =>
            return Final_Elaboration_Legal_Task_Activation_Accepted;
         when Final_Elaboration_Task_Termination =>
            return Final_Elaboration_Legal_Task_Termination_Accepted;
         when Final_Elaboration_Generic_Instance =>
            return Final_Elaboration_Legal_Generic_Instance_Accepted;
         when Final_Elaboration_Generic_Replay =>
            return Final_Elaboration_Legal_Generic_Replay_Accepted;
         when Final_Elaboration_Preelaboration_Policy =>
            return Final_Elaboration_Legal_Preelaboration_Policy_Accepted;
         when Final_Elaboration_Pure_Policy =>
            return Final_Elaboration_Legal_Pure_Policy_Accepted;
         when Final_Elaboration_Remote_Types_Policy =>
            return Final_Elaboration_Legal_Remote_Types_Policy_Accepted;
         when Final_Elaboration_Shared_Passive_Policy =>
            return Final_Elaboration_Legal_Shared_Passive_Policy_Accepted;
         when Final_Elaboration_Unknown =>
            return Final_Elaboration_Indeterminate;
      end case;
   end Legal_Status_For_Kind;

   function Status_From_Elaboration
     (Status : Elab_CPD.Elaboration_Contract_Predicate_Status) return Final_Elaboration_Status is
      Img : constant String := Elab_CPD.Elaboration_Contract_Predicate_Status'Image (Status);
   begin
      if Elab_CPD.Is_Legal (Status) then
         return Final_Elaboration_Not_Checked;
      elsif Has (Img, "INDETERMINATE") or else Has (Img, "NOT_CHECKED") then
         return Final_Elaboration_Indeterminate;
      elsif Has (Img, "READ_BEFORE_WRITE") then
         return Final_Elaboration_Read_Before_Write_Blocker;
      elsif Has (Img, "INITIAL") or else Has (Img, "ASSIGN") or else Has (Img, "MERGE") then
         return Final_Elaboration_Initialization_Blocker;
      elsif Has (Img, "LIFETIME") or else Has (Img, "ACCESS") then
         return Final_Elaboration_Lifetime_Accessibility_Blocker;
      elsif Has (Img, "DISCRIMINANT") then
         return Final_Elaboration_Discriminant_Variant_Blocker;
      elsif Has (Img, "REPRESENTATION") then
         return Final_Elaboration_Representation_Freezing_Blocker;
      elsif Has (Img, "GLOBAL") or else Has (Img, "DEPENDS") then
         return Final_Elaboration_Global_Depends_Blocker;
      elsif Has (Img, "CALL_PROPAGATION") then
         return Final_Elaboration_Call_Propagation_Blocker;
      elsif Has (Img, "GENERIC") then
         return Final_Elaboration_Generic_Effect_Blocker;
      elsif Has (Img, "TASKING") or else Has (Img, "PROTECTED") then
         return Final_Elaboration_Tasking_Protected_Blocker;
      elsif Has (Img, "COVERAGE") then
         return Final_Elaboration_Coverage_Blocker;
      elsif Has (Img, "PREDICATE") or else Has (Img, "CONTRACT") then
         return Final_Elaboration_Predicate_Dataflow_Blocker;
      else
         return Final_Elaboration_Base_Elaboration_Error;
      end if;
   end Status_From_Elaboration;

   function Status_From_Overload
     (Status : Overload_Edge.Overload_Type_Edge_Status) return Final_Elaboration_Status is
      Img : constant String := Overload_Edge.Overload_Type_Edge_Status'Image (Status);
   begin
      if Overload_Edge.Is_Legal (Status) then
         return Final_Elaboration_Not_Checked;
      elsif Has (Img, "AMBIG") then
         return Final_Elaboration_Overload_Type_Ambiguous;
      elsif Has (Img, "INDETERMINATE") or else Has (Img, "NOT_CHECKED") then
         return Final_Elaboration_Indeterminate;
      else
         return Final_Elaboration_Overload_Type_Blocker;
      end if;
   end Status_From_Overload;

   function Status_From_Representation
     (Status : Representation_CPD.Representation_Tasking_CPD_Status) return Final_Elaboration_Status is
      Img : constant String := Representation_CPD.Representation_Tasking_CPD_Status'Image (Status);
   begin
      if Representation_CPD.Is_Legal (Status) then
         return Final_Elaboration_Not_Checked;
      elsif Has (Img, "INDETERMINATE") or else Has (Img, "NOT_CHECKED") then
         return Final_Elaboration_Indeterminate;
      elsif Has (Img, "TASKING") or else Has (Img, "PROTECTED") then
         return Final_Elaboration_Tasking_Protected_Blocker;
      elsif Has (Img, "REPRESENTATION") or else Has (Img, "FREEZING") then
         return Final_Elaboration_Representation_Freezing_Blocker;
      elsif Has (Img, "COVERAGE") then
         return Final_Elaboration_Coverage_Blocker;
      else
         return Final_Elaboration_Representation_Consumer_Blocker;
      end if;
   end Status_From_Representation;

   function Status_From_Tasking
     (Status : Tasking_CPD.Tasking_Contract_Predicate_Status) return Final_Elaboration_Status is
      Img : constant String := Tasking_CPD.Tasking_Contract_Predicate_Status'Image (Status);
   begin
      if Tasking_CPD.Is_Legal (Status) then
         return Final_Elaboration_Not_Checked;
      elsif Has (Img, "INDETERMINATE") or else Has (Img, "NOT_CHECKED") then
         return Final_Elaboration_Indeterminate;
      elsif Has (Img, "ELABORATION") then
         return Final_Elaboration_Base_Elaboration_Error;
      elsif Has (Img, "LIFETIME") or else Has (Img, "ACCESSIBILITY") then
         return Final_Elaboration_Lifetime_Accessibility_Blocker;
      elsif Has (Img, "DISCRIMINANT") then
         return Final_Elaboration_Discriminant_Variant_Blocker;
      elsif Has (Img, "REPRESENTATION") or else Has (Img, "FREEZING") then
         return Final_Elaboration_Representation_Freezing_Blocker;
      elsif Has (Img, "GLOBAL") or else Has (Img, "DEPENDS") then
         return Final_Elaboration_Global_Depends_Blocker;
      elsif Has (Img, "COVERAGE") then
         return Final_Elaboration_Coverage_Blocker;
      else
         return Final_Elaboration_Tasking_Consumer_Blocker;
      end if;
   end Status_From_Tasking;

   function Status_From_Generic_Backmap
     (Status : Generic_Backmap.Generic_Backmap_Status) return Final_Elaboration_Status is
      Img : constant String := Generic_Backmap.Generic_Backmap_Status'Image (Status);
   begin
      if Generic_Backmap.Is_Legal (Status) then
         return Final_Elaboration_Not_Checked;
      elsif Has (Img, "INDETERMINATE") or else Has (Img, "NOT_CHECKED") then
         return Final_Elaboration_Indeterminate;
      else
         return Final_Elaboration_Generic_Backmap_Blocker;
      end if;
   end Status_From_Generic_Backmap;

   function Status_From_Accessibility
     (Status : Access_Final.Master_Scope_Final_Status) return Final_Elaboration_Status is
   begin
      if Access_Final.Is_Legal (Status) then
         return Final_Elaboration_Not_Checked;
      elsif Access_Final.Is_Indeterminate (Status) then
         return Final_Elaboration_Indeterminate;
      else
         return Final_Elaboration_Accessibility_Blocker;
      end if;
   end Status_From_Accessibility;

   function Status_For (Info : Final_Elaboration_Context_Info) return Final_Elaboration_Status is
      Candidate : Final_Elaboration_Status;
   begin
      if Info.Elaboration_Matches > 1 then
         return Final_Elaboration_Multiple_Elaboration_Blockers;
      elsif Info.Elaboration_Row = Elab_CPD.No_Elaboration_Contract_Predicate_Row then
         return Final_Elaboration_Missing_Elaboration_Row;
      end if;

      Candidate := Status_From_Elaboration (Info.Elaboration_Status);
      if Candidate /= Final_Elaboration_Not_Checked then
         return Candidate;
      end if;

      if Info.Requires_Overload then
         if Info.Overload_Matches > 1 then
            return Final_Elaboration_Multiple_Matching_Blockers;
         elsif Info.Overload_Row = Overload_Edge.No_Overload_Type_Edge_Row then
            return Final_Elaboration_Missing_Overload_Row;
         end if;
         Candidate := Status_From_Overload (Info.Overload_Status);
         if Candidate /= Final_Elaboration_Not_Checked then
            return Candidate;
         end if;
      end if;

      if Info.Requires_Representation then
         if Info.Representation_Matches > 1 then
            return Final_Elaboration_Multiple_Matching_Blockers;
         elsif Info.Representation_Row = Representation_CPD.No_Representation_Tasking_CPD_Row then
            return Final_Elaboration_Missing_Representation_Row;
         end if;
         Candidate := Status_From_Representation (Info.Representation_Status);
         if Candidate /= Final_Elaboration_Not_Checked then
            return Candidate;
         end if;
      end if;

      if Info.Requires_Tasking then
         if Info.Tasking_Matches > 1 then
            return Final_Elaboration_Multiple_Matching_Blockers;
         elsif Info.Tasking_Row = Tasking_CPD.No_Tasking_Contract_Predicate_Row then
            return Final_Elaboration_Missing_Tasking_Row;
         end if;
         Candidate := Status_From_Tasking (Info.Tasking_Status);
         if Candidate /= Final_Elaboration_Not_Checked then
            return Candidate;
         end if;
      end if;

      if Info.Requires_Generic_Backmap then
         if Info.Generic_Backmap_Matches > 1 then
            return Final_Elaboration_Multiple_Matching_Blockers;
         elsif Info.Generic_Backmap_Row = Generic_Backmap.No_Generic_Backmap_Row then
            return Final_Elaboration_Missing_Generic_Backmap_Row;
         end if;
         Candidate := Status_From_Generic_Backmap (Info.Generic_Backmap_Status);
         if Candidate /= Final_Elaboration_Not_Checked then
            return Candidate;
         end if;
      end if;

      if Info.Requires_Accessibility then
         if Info.Accessibility_Matches > 1 then
            return Final_Elaboration_Multiple_Matching_Blockers;
         elsif Info.Accessibility_Row = Access_Final.No_Master_Scope_Final_Row then
            return Final_Elaboration_Missing_Accessibility_Row;
         end if;
         Candidate := Status_From_Accessibility (Info.Accessibility_Status);
         if Candidate /= Final_Elaboration_Not_Checked then
            return Candidate;
         end if;
      end if;

      return Legal_Status_For_Kind (Info.Kind);
   end Status_For;

   function Message_For (Status : Final_Elaboration_Status) return Unbounded_String is
   begin
      if Is_Legal (Status) then
         return To_Unbounded_String ("elaboration graph evidence accepted by final consumer");
      elsif Is_Indeterminate (Status) then
         return To_Unbounded_String ("elaboration graph final consumer is indeterminate");
      else
         return To_Unbounded_String ("elaboration graph evidence blocks final consumer legality");
      end if;
   end Message_For;

   function Fingerprint_For (Info : Final_Elaboration_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Final_Elaboration_Context_Kind'Pos (Info.Kind) + 1);
      H := Mix (H, Final_Elaboration_Status'Pos (Info.Status) + 1);
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Info.Source_Fingerprint + 1);
      H := Mix (H, Info.Consumer_Fingerprint + 1);
      return H;
   end Fingerprint_For;

   procedure Clear (Model : in out Final_Elaboration_Context_Model) is
   begin
      Model.Contexts.Clear;
   end Clear;

   procedure Add_Context
     (Model : in out Final_Elaboration_Context_Model;
      Info  : Final_Elaboration_Context_Info) is
   begin
      Model.Contexts.Append (Info);
   end Add_Context;

   function Context_Count (Model : Final_Elaboration_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Final_Elaboration_Context_Model;
      Index : Positive) return Final_Elaboration_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Final_Elaboration_Context_Model) return Natural is
      H : Natural := 0;
   begin
      for C of Model.Contexts loop
         H := Mix (H, Natural (C.Id) + 1);
         H := Mix (H, Final_Elaboration_Context_Kind'Pos (C.Kind) + 1);
         H := Mix (H, Natural (C.Node) + 1);
         H := Mix (H, C.Source_Fingerprint + 1);
         H := Mix (H, C.Consumer_Fingerprint + 1);
      end loop;
      return H;
   end Fingerprint;

   function Build (Contexts : Final_Elaboration_Context_Model) return Final_Elaboration_Model is
      Model  : Final_Elaboration_Model;
      Next   : Final_Elaboration_Row_Id := 1;
      Status : Final_Elaboration_Status;
      Row    : Final_Elaboration_Info;
   begin
      for C of Contexts.Contexts loop
         Status := Status_For (C);
         Row :=
           (Id                    => Next,
            Context               => C.Id,
            Kind                  => C.Kind,
            Status                => Status,
            Node                  => C.Node,
            Context_Name          => C.Context_Name,
            Source_Unit_Name      => C.Source_Unit_Name,
            Target_Unit_Name      => C.Target_Unit_Name,
            Message               => Message_For (Status),
            Detail                => To_Unbounded_String (Final_Elaboration_Status'Image (Status)),
            Elaboration_Row       => C.Elaboration_Row,
            Elaboration_Status    => C.Elaboration_Status,
            Overload_Row          => C.Overload_Row,
            Overload_Status       => C.Overload_Status,
            Representation_Row    => C.Representation_Row,
            Representation_Status => C.Representation_Status,
            Tasking_Row           => C.Tasking_Row,
            Tasking_Status        => C.Tasking_Status,
            Generic_Backmap_Row   => C.Generic_Backmap_Row,
            Generic_Backmap_Status => C.Generic_Backmap_Status,
            Accessibility_Row     => C.Accessibility_Row,
            Accessibility_Status  => C.Accessibility_Status,
            Source_Fingerprint    => C.Source_Fingerprint,
            Consumer_Fingerprint  => C.Consumer_Fingerprint,
            Fingerprint           => 0);
         Row.Fingerprint := Fingerprint_For (Row);
         Model.Rows.Append (Row);
         Model.Model_Fingerprint := Mix (Model.Model_Fingerprint, Row.Fingerprint);
         Next := Next + 1;
      end loop;
      return Model;
   end Build;

   function Row_Count (Model : Final_Elaboration_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : Final_Elaboration_Model;
      Index : Positive) return Final_Elaboration_Info is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function First_For_Node
     (Model : Final_Elaboration_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Final_Elaboration_Info is
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Final_Elaboration_Model;
      Status : Final_Elaboration_Status) return Final_Elaboration_Set is
      Result : Final_Elaboration_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Final_Elaboration_Model;
      Kind  : Final_Elaboration_Context_Kind) return Final_Elaboration_Set is
      Result : Final_Elaboration_Set;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Kind;

   function Rows_For_Context_Name
     (Model        : Final_Elaboration_Model;
      Context_Name : String) return Final_Elaboration_Set is
      Result : Final_Elaboration_Set;
   begin
      for Row of Model.Rows loop
         if To_String (Row.Context_Name) = Context_Name then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Context_Name;

   function Set_Count (Set : Final_Elaboration_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Set_Count;

   function Set_At
     (Set   : Final_Elaboration_Set;
      Index : Positive) return Final_Elaboration_Info is
   begin
      return Set.Rows.Element (Index);
   end Set_At;

   function Count_Status
     (Model  : Final_Elaboration_Model;
      Status : Final_Elaboration_Status) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind
     (Model : Final_Elaboration_Model;
      Kind  : Final_Elaboration_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : Final_Elaboration_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Legal (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Legal_Count;

   function Error_Count (Model : Final_Elaboration_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if not Is_Legal (Row.Status) and then not Is_Indeterminate (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Error_Count;

   function Elaboration_Error_Count (Model : Final_Elaboration_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Elaboration_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Elaboration_Error_Count;

   function Overload_Error_Count (Model : Final_Elaboration_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Overload_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Overload_Error_Count;

   function Representation_Error_Count (Model : Final_Elaboration_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Representation_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Representation_Error_Count;

   function Tasking_Error_Count (Model : Final_Elaboration_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Tasking_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Tasking_Error_Count;

   function Generic_Backmap_Error_Count (Model : Final_Elaboration_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Generic_Backmap_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Generic_Backmap_Error_Count;

   function Accessibility_Error_Count (Model : Final_Elaboration_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Accessibility_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Accessibility_Error_Count;

   function Indeterminate_Count (Model : Final_Elaboration_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Indeterminate (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Indeterminate_Count;

   function Fingerprint (Model : Final_Elaboration_Model) return Natural is
   begin
      return Model.Model_Fingerprint;
   end Fingerprint;

   function Is_Legal (Status : Final_Elaboration_Status) return Boolean is
   begin
      return Status in Final_Elaboration_Legal_Call_Accepted ..
                       Final_Elaboration_Legal_Shared_Passive_Policy_Accepted;
   end Is_Legal;

   function Is_Elaboration_Error (Status : Final_Elaboration_Status) return Boolean is
   begin
      return Status in Final_Elaboration_Missing_Elaboration_Row |
                       Final_Elaboration_Multiple_Elaboration_Blockers |
                       Final_Elaboration_Base_Elaboration_Error |
                       Final_Elaboration_Predicate_Dataflow_Blocker |
                       Final_Elaboration_Read_Before_Write_Blocker |
                       Final_Elaboration_Initialization_Blocker |
                       Final_Elaboration_Lifetime_Accessibility_Blocker |
                       Final_Elaboration_Discriminant_Variant_Blocker |
                       Final_Elaboration_Global_Depends_Blocker |
                       Final_Elaboration_Call_Propagation_Blocker |
                       Final_Elaboration_Generic_Effect_Blocker |
                       Final_Elaboration_Tasking_Protected_Blocker |
                       Final_Elaboration_Coverage_Blocker;
   end Is_Elaboration_Error;

   function Is_Overload_Error (Status : Final_Elaboration_Status) return Boolean is
   begin
      return Status in Final_Elaboration_Missing_Overload_Row |
                       Final_Elaboration_Overload_Type_Blocker |
                       Final_Elaboration_Overload_Type_Ambiguous;
   end Is_Overload_Error;

   function Is_Representation_Error (Status : Final_Elaboration_Status) return Boolean is
   begin
      return Status in Final_Elaboration_Missing_Representation_Row |
                       Final_Elaboration_Representation_Consumer_Blocker |
                       Final_Elaboration_Representation_Freezing_Blocker;
   end Is_Representation_Error;

   function Is_Tasking_Error (Status : Final_Elaboration_Status) return Boolean is
   begin
      return Status in Final_Elaboration_Missing_Tasking_Row |
                       Final_Elaboration_Tasking_Consumer_Blocker |
                       Final_Elaboration_Tasking_Protected_Blocker;
   end Is_Tasking_Error;

   function Is_Generic_Backmap_Error (Status : Final_Elaboration_Status) return Boolean is
   begin
      return Status in Final_Elaboration_Missing_Generic_Backmap_Row |
                       Final_Elaboration_Generic_Backmap_Blocker;
   end Is_Generic_Backmap_Error;

   function Is_Accessibility_Error (Status : Final_Elaboration_Status) return Boolean is
   begin
      return Status in Final_Elaboration_Missing_Accessibility_Row |
                       Final_Elaboration_Accessibility_Blocker |
                       Final_Elaboration_Lifetime_Accessibility_Blocker;
   end Is_Accessibility_Error;

   function Is_Indeterminate (Status : Final_Elaboration_Status) return Boolean is
   begin
      return Status = Final_Elaboration_Indeterminate;
   end Is_Indeterminate;

end Editor.Ada_Elaboration_Graph_Final_Consumer_Legality;
