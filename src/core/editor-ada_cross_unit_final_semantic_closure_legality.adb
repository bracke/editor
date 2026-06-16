with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality is

   pragma Suppress (Overflow_Check);

   use type Access_Final.Master_Scope_Final_Row_Id;
   use type Access_Final.Master_Scope_Final_Status;
   use type Completion.Completion_Legality_Id;
   use type Completion.Completion_Legality_Status;
   use type Contract_CPD.Contract_Predicate_Row_Id;
   use type Contract_CPD.Contract_Predicate_Status;
   use type Dataflow_Init.Dataflow_Init_Row_Id;
   use type Dataflow_Init.Dataflow_Init_Status;
   use type Disc_Consumer.Discriminant_Consumer_Row_Id;
   use type Disc_Consumer.Discriminant_Consumer_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Elab_Final.Final_Elaboration_Row_Id;
   use type Elab_Final.Final_Elaboration_Status;
   use type Exceptions.Exception_Legality_Id;
   use type Exceptions.Exception_Legality_Status;
   use type Generic_Backmap.Generic_Backmap_Row_Id;
   use type Generic_Backmap.Generic_Backmap_Status;
   use type Integrated.Integrated_Closure_Status;
   use type Overload_Edge.Overload_Type_Edge_Row_Id;
   use type Overload_Edge.Overload_Type_Edge_Status;
   use type Refined.Refined_Conformance_Id;
   use type Refined.Refined_Conformance_Status;
   use type Renaming.Renaming_Legality_Id;
   use type Renaming.Renaming_Legality_Status;
   use type Rep_CPD.Representation_Tasking_CPD_Row_Id;
   use type Rep_CPD.Representation_Tasking_CPD_Status;
   use type Tasking_Final.Final_Tasking_Row_Id;
   use type Tasking_Final.Final_Tasking_Status;

   function Has (Text : String; Needle : String) return Boolean is
      L_Text   : constant String := Ada.Characters.Handling.To_Lower (Text);
      L_Needle : constant String := Ada.Characters.Handling.To_Lower (Needle);
   begin
      if Needle'Length = 0 or else Text'Length < Needle'Length then
         return False;
      end if;
      for I in L_Text'First .. L_Text'Last - L_Needle'Length + 1 loop
         if L_Text (I .. I + L_Needle'Length - 1) = L_Needle then
            return True;
         end if;
      end loop;
      return False;
   end Has;

   function Mix (Seed : Natural; Value : Natural) return Natural is
   begin
      return (Seed * 131 + Value * 17 + 97) mod 2_147_483_647;
   end Mix;

   function Image_Hash (Text : String) return Natural is
      H : Natural := 0;
   begin
      for Ch of Text loop
         H := Mix (H, Character'Pos (Ch));
      end loop;
      return H;
   end Image_Hash;

   function Legal_Integrated (Status : Integrated.Integrated_Closure_Status) return Boolean is
   begin
      return Status in Integrated.Integrated_Closure_Legal_Local ..
                       Integrated.Integrated_Closure_Legal_With_Use_Closure;
   end Legal_Integrated;

   function Legal_Contract (Status : Contract_CPD.Contract_Predicate_Status) return Boolean is
   begin
      return Status in Contract_CPD.Contract_Predicate_Legal_Precondition_Accepted ..
                       Contract_CPD.Contract_Predicate_Legal_Refined_Depends_Accepted;
   end Legal_Contract;

   function Legal_Completion (Status : Completion.Completion_Legality_Status) return Boolean is
   begin
      return Status in Completion.Completion_Legality_Legal_Unit_Body ..
                       Completion.Completion_Legality_Legal_Declaration_Order;
   end Legal_Completion;

   function Legal_Renaming (Status : Renaming.Renaming_Legality_Status) return Boolean is
   begin
      return Status in Renaming.Renaming_Legality_Legal_Object_Renaming ..
                       Renaming.Renaming_Legality_Legal_Selected_Alias;
   end Legal_Renaming;

   function Legal_Exception (Status : Exceptions.Exception_Legality_Status) return Boolean is
   begin
      return Status in Exceptions.Exception_Legality_Legal_Raise_Statement ..
                       Exceptions.Exception_Legality_Legal_No_Return;
   end Legal_Exception;

   function Accepted_For (Info : Cross_Unit_Final_Context_Info) return Cross_Unit_Final_Status is
   begin
      case Info.Kind is
         when Cross_Unit_Final_Local => return Cross_Unit_Final_Local_Accepted;
         when Cross_Unit_Final_With_Use => return Cross_Unit_Final_With_Use_Accepted;
         when Cross_Unit_Final_Private_Full_View => return Cross_Unit_Final_Private_Full_View_Accepted;
         when Cross_Unit_Final_Limited_View => return Cross_Unit_Final_Limited_View_Accepted;
         when Cross_Unit_Final_Child_Private_Child => return Cross_Unit_Final_Child_Private_Child_Accepted;
         when Cross_Unit_Final_Separate_Body => return Cross_Unit_Final_Separate_Body_Accepted;
         when Cross_Unit_Final_Generic_Instance | Cross_Unit_Final_Generic_Backmapping => return Cross_Unit_Final_Generic_Instance_Accepted;
         when Cross_Unit_Final_Representation => return Cross_Unit_Final_Representation_Accepted;
         when Cross_Unit_Final_Elaboration => return Cross_Unit_Final_Elaboration_Accepted;
         when Cross_Unit_Final_Tasking_Protected => return Cross_Unit_Final_Tasking_Protected_Accepted;
         when others => return Cross_Unit_Final_Accepted;
      end case;
   end Accepted_For;

   function Status_From_Integrated
     (Status : Integrated.Integrated_Closure_Status) return Cross_Unit_Final_Status is
      Img : constant String := Integrated.Integrated_Closure_Status'Image (Status);
   begin
      if Legal_Integrated (Status) or else Status = Integrated.Integrated_Closure_Not_Checked then
         return Cross_Unit_Final_Not_Checked;
      elsif Has (Img, "INDETERMINATE") then
         return Cross_Unit_Final_Indeterminate;
      elsif Has (Img, "MISSING_DEPENDENCY") then
         return Cross_Unit_Final_Missing_Dependency;
      elsif Has (Img, "AMBIGUOUS_DEPENDENCY") then
         return Cross_Unit_Final_Ambiguous_Dependency;
      elsif Has (Img, "OVERFLOW") then
         return Cross_Unit_Final_Dependency_Overflow;
      elsif Has (Img, "STALE") or else Has (Img, "REJECTED") then
         return Cross_Unit_Final_Stale_Dependency;
      elsif Has (Img, "LIMITED_VIEW") then
         return Cross_Unit_Final_Limited_View_Barrier;
      elsif Has (Img, "PRIVATE_VIEW") then
         return Cross_Unit_Final_Private_View_Barrier;
      elsif Has (Img, "OVERLOAD") then
         return Cross_Unit_Final_Overload_Type_Edge_Blocker;
      elsif Has (Img, "ACCESS") then
         return Cross_Unit_Final_Accessibility_Lifetime_Blocker;
      elsif Has (Img, "CONTRACT") or else Has (Img, "PREDICATE") then
         return Cross_Unit_Final_Contract_Dataflow_Blocker;
      elsif Has (Img, "ELABORATION") then
         return Cross_Unit_Final_Elaboration_Dependence_Blocker;
      elsif Has (Img, "COMPLETION") then
         return Cross_Unit_Final_Body_Spec_Completion_Blocker;
      elsif Has (Img, "RENAMING") then
         return Cross_Unit_Final_Renaming_Alias_Visibility_Blocker;
      elsif Has (Img, "EXCEPTION") or else Has (Img, "FINALIZATION") then
         return Cross_Unit_Final_Exception_Finalization_Blocker;
      elsif Has (Img, "REPRESENTATION") then
         return Cross_Unit_Final_Representation_Freezing_Blocker;
      elsif Has (Img, "DATAFLOW") or else Has (Img, "INITIALIZATION") or else Has (Img, "REFINED") then
         return Cross_Unit_Final_Contract_Dataflow_Blocker;
      elsif Has (Img, "AST") then
         return Cross_Unit_Final_AST_Repair_Blocker;
      elsif Has (Img, "COVERAGE") then
         return Cross_Unit_Final_Coverage_Gate_Blocker;
      elsif Has (Img, "MULTIPLE") then
         return Cross_Unit_Final_Multiple_Blockers;
      else
         return Cross_Unit_Final_Integrated_Closure_Blocker;
      end if;
   end Status_From_Integrated;

   function Status_From_Overload
     (Status : Overload_Edge.Overload_Type_Edge_Status) return Cross_Unit_Final_Status is
      Img : constant String := Overload_Edge.Overload_Type_Edge_Status'Image (Status);
   begin
      if Overload_Edge.Is_Legal (Status) or else Status = Overload_Edge.Overload_Type_Edge_Not_Checked then
         return Cross_Unit_Final_Not_Checked;
      elsif Has (Img, "INDETERMINATE") then
         return Cross_Unit_Final_Indeterminate;
      elsif Has (Img, "DISPATCH") or else Has (Img, "INHERITED") or else Has (Img, "PRIMITIVE") or else Has (Img, "CONTROLLING") then
         return Cross_Unit_Final_Dispatching_Inherited_Primitive_Blocker;
      elsif Has (Img, "AST") then
         return Cross_Unit_Final_AST_Repair_Blocker;
      elsif Has (Img, "COVERAGE") then
         return Cross_Unit_Final_Coverage_Gate_Blocker;
      elsif Has (Img, "GENERIC_REPLAY") then
         return Cross_Unit_Final_Generic_Backmapping_Blocker;
      else
         return Cross_Unit_Final_Overload_Type_Edge_Blocker;
      end if;
   end Status_From_Overload;

   function Status_From_Generic_Backmap
     (Status : Generic_Backmap.Generic_Backmap_Status) return Cross_Unit_Final_Status is
      Img : constant String := Generic_Backmap.Generic_Backmap_Status'Image (Status);
   begin
      if Generic_Backmap.Is_Legal (Status) or else Status = Generic_Backmap.Generic_Backmap_Not_Checked then
         return Cross_Unit_Final_Not_Checked;
      elsif Has (Img, "INDETERMINATE") then
         return Cross_Unit_Final_Indeterminate;
      elsif Has (Img, "OVERLOAD") then
         return Cross_Unit_Final_Overload_Type_Edge_Blocker;
      elsif Has (Img, "REPLAY_CPD") or else Has (Img, "MAPPING") or else Has (Img, "MAP") or else Has (Img, "FINGERPRINT") then
         return Cross_Unit_Final_Generic_Backmapping_Blocker;
      else
         return Cross_Unit_Final_Generic_Body_Unavailable;
      end if;
   end Status_From_Generic_Backmap;

   function Status_From_Discriminant
     (Status : Disc_Consumer.Discriminant_Consumer_Status) return Cross_Unit_Final_Status is
      Img : constant String := Disc_Consumer.Discriminant_Consumer_Status'Image (Status);
   begin
      if Disc_Consumer.Is_Legal (Status) or else Status = Disc_Consumer.Discriminant_Consumer_Not_Checked then
         return Cross_Unit_Final_Not_Checked;
      elsif Has (Img, "INDETERMINATE") then
         return Cross_Unit_Final_Indeterminate;
      elsif Has (Img, "AST") then
         return Cross_Unit_Final_AST_Repair_Blocker;
      elsif Has (Img, "GENERIC") then
         return Cross_Unit_Final_Generic_Backmapping_Blocker;
      elsif Has (Img, "REPRESENTATION") or else Has (Img, "FREEZING") then
         return Cross_Unit_Final_Representation_Freezing_Blocker;
      else
         return Cross_Unit_Final_Discriminant_Variant_Blocker;
      end if;
   end Status_From_Discriminant;

   function Status_From_Accessibility
     (Status : Access_Final.Master_Scope_Final_Status) return Cross_Unit_Final_Status is
      Img : constant String := Access_Final.Master_Scope_Final_Status'Image (Status);
   begin
      if Access_Final.Is_Legal (Status) or else Status = Access_Final.Master_Scope_Final_Not_Checked then
         return Cross_Unit_Final_Not_Checked;
      elsif Access_Final.Is_Indeterminate (Status) then
         return Cross_Unit_Final_Indeterminate;
      elsif Has (Img, "DISCRIMINANT") then
         return Cross_Unit_Final_Discriminant_Variant_Blocker;
      elsif Has (Img, "GENERIC") then
         return Cross_Unit_Final_Generic_Backmapping_Blocker;
      elsif Has (Img, "REPRESENTATION") or else Has (Img, "FREEZING") then
         return Cross_Unit_Final_Representation_Freezing_Blocker;
      elsif Has (Img, "COVERAGE") then
         return Cross_Unit_Final_Coverage_Gate_Blocker;
      else
         return Cross_Unit_Final_Accessibility_Lifetime_Blocker;
      end if;
   end Status_From_Accessibility;

   function Status_From_Elaboration
     (Status : Elab_Final.Final_Elaboration_Status) return Cross_Unit_Final_Status is
      Img : constant String := Elab_Final.Final_Elaboration_Status'Image (Status);
   begin
      if Elab_Final.Is_Legal (Status) or else Status = Elab_Final.Final_Elaboration_Not_Checked then
         return Cross_Unit_Final_Not_Checked;
      elsif Elab_Final.Is_Indeterminate (Status) then
         return Cross_Unit_Final_Indeterminate;
      elsif Has (Img, "OVERLOAD") then
         return Cross_Unit_Final_Overload_Type_Edge_Blocker;
      elsif Has (Img, "GENERIC") then
         return Cross_Unit_Final_Generic_Backmapping_Blocker;
      elsif Has (Img, "REPRESENTATION") then
         return Cross_Unit_Final_Representation_Freezing_Blocker;
      elsif Has (Img, "TASKING") then
         return Cross_Unit_Final_Tasking_Protected_Final_Effect_Blocker;
      elsif Has (Img, "ACCESS") or else Has (Img, "LIFETIME") then
         return Cross_Unit_Final_Accessibility_Lifetime_Blocker;
      elsif Has (Img, "DISCRIMINANT") then
         return Cross_Unit_Final_Discriminant_Variant_Blocker;
      elsif Has (Img, "PREDICATE") or else Has (Img, "CONTRACT") then
         return Cross_Unit_Final_Predicate_Invariant_Blocker;
      elsif Has (Img, "GLOBAL") or else Has (Img, "DEPENDS") or else Has (Img, "INITIAL") then
         return Cross_Unit_Final_Contract_Dataflow_Blocker;
      elsif Has (Img, "COVERAGE") then
         return Cross_Unit_Final_Coverage_Gate_Blocker;
      else
         return Cross_Unit_Final_Elaboration_Dependence_Blocker;
      end if;
   end Status_From_Elaboration;

   function Status_From_Tasking
     (Status : Tasking_Final.Final_Tasking_Status) return Cross_Unit_Final_Status is
      Img : constant String := Tasking_Final.Final_Tasking_Status'Image (Status);
   begin
      if Tasking_Final.Is_Legal (Status) or else Status = Tasking_Final.Final_Tasking_Not_Checked then
         return Cross_Unit_Final_Not_Checked;
      elsif Tasking_Final.Is_Indeterminate (Status) then
         return Cross_Unit_Final_Indeterminate;
      elsif Has (Img, "REPRESENTATION") then
         return Cross_Unit_Final_Representation_Freezing_Blocker;
      elsif Has (Img, "ACCESS") or else Has (Img, "LIFETIME") then
         return Cross_Unit_Final_Accessibility_Lifetime_Blocker;
      elsif Has (Img, "DISCRIMINANT") then
         return Cross_Unit_Final_Discriminant_Variant_Blocker;
      elsif Has (Img, "GLOBAL") or else Has (Img, "DEPENDS") or else Has (Img, "INITIAL") or else Has (Img, "PREDICATE") then
         return Cross_Unit_Final_Contract_Dataflow_Blocker;
      elsif Has (Img, "COVERAGE") then
         return Cross_Unit_Final_Coverage_Gate_Blocker;
      else
         return Cross_Unit_Final_Tasking_Protected_Final_Effect_Blocker;
      end if;
   end Status_From_Tasking;

   function Status_From_Representation
     (Status : Rep_CPD.Representation_Tasking_CPD_Status) return Cross_Unit_Final_Status is
      Img : constant String := Rep_CPD.Representation_Tasking_CPD_Status'Image (Status);
   begin
      if Rep_CPD.Is_Legal (Status) or else Status = Rep_CPD.Representation_Tasking_CPD_Not_Checked then
         return Cross_Unit_Final_Not_Checked;
      elsif Has (Img, "INDETERMINATE") then
         return Cross_Unit_Final_Indeterminate;
      elsif Has (Img, "COVERAGE") then
         return Cross_Unit_Final_Coverage_Gate_Blocker;
      elsif Has (Img, "TARGET") then
         return Cross_Unit_Final_Representation_Target_Blocker;
      else
         return Cross_Unit_Final_Representation_Freezing_Blocker;
      end if;
   end Status_From_Representation;

   function Status_From_Contract
     (Status : Contract_CPD.Contract_Predicate_Status) return Cross_Unit_Final_Status is
      Img : constant String := Contract_CPD.Contract_Predicate_Status'Image (Status);
   begin
      if Legal_Contract (Status) or else Status = Contract_CPD.Contract_Predicate_Not_Checked then
         return Cross_Unit_Final_Not_Checked;
      elsif Has (Img, "INDETERMINATE") then
         return Cross_Unit_Final_Indeterminate;
      elsif Has (Img, "PREDICATE") or else Has (Img, "INVARIANT") then
         return Cross_Unit_Final_Predicate_Invariant_Blocker;
      elsif Has (Img, "COVERAGE") then
         return Cross_Unit_Final_Coverage_Gate_Blocker;
      else
         return Cross_Unit_Final_Contract_Dataflow_Blocker;
      end if;
   end Status_From_Contract;

   function Status_From_Dataflow
     (Status : Dataflow_Init.Dataflow_Init_Status) return Cross_Unit_Final_Status is
      Img : constant String := Dataflow_Init.Dataflow_Init_Status'Image (Status);
   begin
      if Dataflow_Init.Is_Legal (Status) or else Status = Dataflow_Init.Dataflow_Init_Not_Checked then
         return Cross_Unit_Final_Not_Checked;
      elsif Has (Img, "INDETERMINATE") then
         return Cross_Unit_Final_Indeterminate;
      elsif Has (Img, "COVERAGE") then
         return Cross_Unit_Final_Coverage_Gate_Blocker;
      elsif Has (Img, "LIFETIME") then
         return Cross_Unit_Final_Accessibility_Lifetime_Blocker;
      elsif Has (Img, "DISCRIMINANT") then
         return Cross_Unit_Final_Discriminant_Variant_Blocker;
      else
         return Cross_Unit_Final_Contract_Dataflow_Blocker;
      end if;
   end Status_From_Dataflow;

   function Status_From_Refined
     (Status : Refined.Refined_Conformance_Status) return Cross_Unit_Final_Status is
      Img : constant String := Refined.Refined_Conformance_Status'Image (Status);
   begin
      if Refined.Is_Legal (Status) or else Status = Refined.Refined_Conformance_Not_Checked then
         return Cross_Unit_Final_Not_Checked;
      elsif Has (Img, "INDETERMINATE") then
         return Cross_Unit_Final_Indeterminate;
      elsif Has (Img, "COVERAGE") then
         return Cross_Unit_Final_Coverage_Gate_Blocker;
      else
         return Cross_Unit_Final_Refined_Global_Depends_Blocker;
      end if;
   end Status_From_Refined;

   function Status_From_Completion
     (Status : Completion.Completion_Legality_Status) return Cross_Unit_Final_Status is
      Img : constant String := Completion.Completion_Legality_Status'Image (Status);
   begin
      if Legal_Completion (Status) or else Status = Completion.Completion_Legality_Not_Checked then
         return Cross_Unit_Final_Not_Checked;
      elsif Has (Img, "INDETERMINATE") then
         return Cross_Unit_Final_Indeterminate;
      elsif Has (Img, "LIMITED_VIEW") then
         return Cross_Unit_Final_Limited_View_Barrier;
      elsif Has (Img, "PRIVATE_VIEW") then
         return Cross_Unit_Final_Private_View_Barrier;
      elsif Has (Img, "SEPARATE") then
         return Cross_Unit_Final_Separate_Body_Blocker;
      else
         return Cross_Unit_Final_Body_Spec_Completion_Blocker;
      end if;
   end Status_From_Completion;

   function Status_From_Renaming
     (Status : Renaming.Renaming_Legality_Status) return Cross_Unit_Final_Status is
      Img : constant String := Renaming.Renaming_Legality_Status'Image (Status);
   begin
      if Legal_Renaming (Status) or else Status = Renaming.Renaming_Legality_Not_Checked then
         return Cross_Unit_Final_Not_Checked;
      elsif Has (Img, "INDETERMINATE") then
         return Cross_Unit_Final_Indeterminate;
      elsif Has (Img, "LIMITED_VIEW") then
         return Cross_Unit_Final_Limited_View_Barrier;
      elsif Has (Img, "PRIVATE_VIEW") then
         return Cross_Unit_Final_Private_View_Barrier;
      elsif Has (Img, "OVERLOAD") then
         return Cross_Unit_Final_Overload_Type_Edge_Blocker;
      elsif Has (Img, "ACCESS") then
         return Cross_Unit_Final_Accessibility_Lifetime_Blocker;
      else
         return Cross_Unit_Final_Renaming_Alias_Visibility_Blocker;
      end if;
   end Status_From_Renaming;

   function Status_From_Exception
     (Status : Exceptions.Exception_Legality_Status) return Cross_Unit_Final_Status is
      Img : constant String := Exceptions.Exception_Legality_Status'Image (Status);
   begin
      if Legal_Exception (Status) or else Status = Exceptions.Exception_Legality_Not_Checked then
         return Cross_Unit_Final_Not_Checked;
      elsif Has (Img, "INDETERMINATE") then
         return Cross_Unit_Final_Indeterminate;
      elsif Has (Img, "LIMITED_VIEW") then
         return Cross_Unit_Final_Limited_View_Barrier;
      elsif Has (Img, "PRIVATE_VIEW") then
         return Cross_Unit_Final_Private_View_Barrier;
      elsif Has (Img, "ACCESS") then
         return Cross_Unit_Final_Accessibility_Lifetime_Blocker;
      elsif Has (Img, "CONTRACT") or else Has (Img, "FLOW") then
         return Cross_Unit_Final_Contract_Dataflow_Blocker;
      elsif Has (Img, "ELABORATION") then
         return Cross_Unit_Final_Elaboration_Dependence_Blocker;
      elsif Has (Img, "RENAMING") then
         return Cross_Unit_Final_Renaming_Alias_Visibility_Blocker;
      elsif Has (Img, "COMPLETION") then
         return Cross_Unit_Final_Body_Spec_Completion_Blocker;
      else
         return Cross_Unit_Final_Exception_Finalization_Blocker;
      end if;
   end Status_From_Exception;

   function First_Blocker (Info : Cross_Unit_Final_Context_Info) return Cross_Unit_Final_Status is
      Candidate : Cross_Unit_Final_Status;
   begin
      if Info.Blocker_Count > 1 then
         return Cross_Unit_Final_Multiple_Blockers;
      elsif Info.Missing_Dependency or else Info.Dependency = Dependency_Missing then
         return Cross_Unit_Final_Missing_Dependency;
      elsif Info.Ambiguous_Dependency or else Info.Dependency = Dependency_Ambiguous then
         return Cross_Unit_Final_Ambiguous_Dependency;
      elsif Info.Dependency_Overflow or else Info.Dependency = Dependency_Overflow then
         return Cross_Unit_Final_Dependency_Overflow;
      elsif Info.Stale_Dependency or else Info.Dependency = Dependency_Stale then
         return Cross_Unit_Final_Stale_Dependency;
      elsif Info.Limited_View_Barrier or else Info.Dependency = Dependency_Limited_View then
         return Cross_Unit_Final_Limited_View_Barrier;
      elsif Info.Private_View_Barrier then
         return Cross_Unit_Final_Private_View_Barrier;
      elsif Info.Child_Visibility_Blocked then
         return Cross_Unit_Final_Child_Visibility_Blocker;
      elsif Info.Separate_Body_Blocked then
         return Cross_Unit_Final_Separate_Body_Blocker;
      end if;

      Candidate := Status_From_Integrated (Info.Integrated_Status);
      if Candidate /= Cross_Unit_Final_Not_Checked then
         return Candidate;
      end if;

      if Info.Requires_Overload and then Info.Overload_Row = Overload_Edge.No_Overload_Type_Edge_Row then
         return Cross_Unit_Final_Overload_Type_Edge_Blocker;
      end if;
      Candidate := Status_From_Overload (Info.Overload_Status);
      if Candidate /= Cross_Unit_Final_Not_Checked then
         return Candidate;
      end if;

      if Info.Requires_Generic_Backmap and then Info.Generic_Backmap_Row = Generic_Backmap.No_Generic_Backmap_Row then
         return Cross_Unit_Final_Generic_Backmapping_Blocker;
      end if;
      Candidate := Status_From_Generic_Backmap (Info.Generic_Backmap_Status);
      if Candidate /= Cross_Unit_Final_Not_Checked then
         return Candidate;
      end if;

      if Info.Requires_Discriminant and then Info.Discriminant_Row = Disc_Consumer.No_Discriminant_Consumer_Row then
         return Cross_Unit_Final_Discriminant_Variant_Blocker;
      end if;
      Candidate := Status_From_Discriminant (Info.Discriminant_Status);
      if Candidate /= Cross_Unit_Final_Not_Checked then
         return Candidate;
      end if;

      if Info.Requires_Accessibility and then Info.Accessibility_Row = Access_Final.No_Master_Scope_Final_Row then
         return Cross_Unit_Final_Accessibility_Lifetime_Blocker;
      end if;
      Candidate := Status_From_Accessibility (Info.Accessibility_Status);
      if Candidate /= Cross_Unit_Final_Not_Checked then
         return Candidate;
      end if;

      if Info.Requires_Elaboration and then Info.Elaboration_Row = Elab_Final.No_Final_Elaboration_Row then
         return Cross_Unit_Final_Elaboration_Dependence_Blocker;
      end if;
      Candidate := Status_From_Elaboration (Info.Elaboration_Status);
      if Candidate /= Cross_Unit_Final_Not_Checked then
         return Candidate;
      end if;

      if Info.Requires_Tasking and then Info.Tasking_Row = Tasking_Final.No_Final_Tasking_Row then
         return Cross_Unit_Final_Tasking_Protected_Final_Effect_Blocker;
      end if;
      Candidate := Status_From_Tasking (Info.Tasking_Status);
      if Candidate /= Cross_Unit_Final_Not_Checked then
         return Candidate;
      end if;

      if Info.Requires_Representation and then Info.Representation_Row = Rep_CPD.No_Representation_Tasking_CPD_Row then
         return Cross_Unit_Final_Representation_Target_Blocker;
      end if;
      Candidate := Status_From_Representation (Info.Representation_Status);
      if Candidate /= Cross_Unit_Final_Not_Checked then
         return Candidate;
      end if;

      if Info.Requires_Contract and then Info.Contract_Row = Contract_CPD.No_Contract_Predicate_Row then
         return Cross_Unit_Final_Contract_Dataflow_Blocker;
      end if;
      Candidate := Status_From_Contract (Info.Contract_Status);
      if Candidate /= Cross_Unit_Final_Not_Checked then
         return Candidate;
      end if;

      if Info.Requires_Dataflow and then Info.Dataflow_Row = Dataflow_Init.No_Dataflow_Init_Row then
         return Cross_Unit_Final_Contract_Dataflow_Blocker;
      end if;
      Candidate := Status_From_Dataflow (Info.Dataflow_Status);
      if Candidate /= Cross_Unit_Final_Not_Checked then
         return Candidate;
      end if;

      if Info.Requires_Refined and then Info.Refined_Row = Refined.No_Refined_Conformance then
         return Cross_Unit_Final_Refined_Global_Depends_Blocker;
      end if;
      Candidate := Status_From_Refined (Info.Refined_Status);
      if Candidate /= Cross_Unit_Final_Not_Checked then
         return Candidate;
      end if;

      if Info.Requires_Completion and then Info.Completion_Row = Completion.No_Completion_Legality then
         return Cross_Unit_Final_Body_Spec_Completion_Blocker;
      end if;
      Candidate := Status_From_Completion (Info.Completion_Status);
      if Candidate /= Cross_Unit_Final_Not_Checked then
         return Candidate;
      end if;

      if Info.Requires_Renaming and then Info.Renaming_Row = Renaming.No_Renaming_Legality then
         return Cross_Unit_Final_Renaming_Alias_Visibility_Blocker;
      end if;
      Candidate := Status_From_Renaming (Info.Renaming_Status);
      if Candidate /= Cross_Unit_Final_Not_Checked then
         return Candidate;
      end if;

      if Info.Requires_Exception and then Info.Exception_Row = Exceptions.No_Exception_Legality then
         return Cross_Unit_Final_Exception_Finalization_Blocker;
      end if;
      Candidate := Status_From_Exception (Info.Exception_Status);
      if Candidate /= Cross_Unit_Final_Not_Checked then
         return Candidate;
      end if;

      return Accepted_For (Info);
   end First_Blocker;

   function Message_For (Status : Cross_Unit_Final_Status) return Unbounded_String is
   begin
      return To_Unbounded_String (Cross_Unit_Final_Status'Image (Status));
   end Message_For;

   function Fingerprint_For (Row : Cross_Unit_Final_Info) return Natural is
      H : Natural := 1186;
   begin
      H := Mix (H, Cross_Unit_Final_Row_Id'Pos (Row.Id) + 1);
      H := Mix (H, Cross_Unit_Final_Context_Kind'Pos (Row.Kind) + 1);
      H := Mix (H, Cross_Unit_Dependency_State'Pos (Row.Dependency) + 1);
      H := Mix (H, Cross_Unit_Final_Status'Pos (Row.Status) + 1);
      H := Mix (H, Natural (Row.Node) + 1);
      H := Mix (H, Image_Hash (To_String (Row.Unit_Name)));
      H := Mix (H, Image_Hash (To_String (Row.Dependency_Name)));
      H := Mix (H, Row.Source_Fingerprint + 1);
      H := Mix (H, Row.Closure_Fingerprint + 1);
      H := Mix (H, Row.Consumer_Fingerprint + 1);
      return H;
   end Fingerprint_For;

   procedure Clear (Model : in out Cross_Unit_Final_Context_Model) is
   begin
      Model.Contexts.Clear;
   end Clear;

   procedure Add_Context (Model : in out Cross_Unit_Final_Context_Model; Info : Cross_Unit_Final_Context_Info) is
   begin
      Model.Contexts.Append (Info);
   end Add_Context;

   function Context_Count (Model : Cross_Unit_Final_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At (Model : Cross_Unit_Final_Context_Model; Index : Positive) return Cross_Unit_Final_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Cross_Unit_Final_Context_Model) return Natural is
      H : Natural := 1186;
   begin
      for C of Model.Contexts loop
         H := Mix (H, Cross_Unit_Final_Row_Id'Pos (C.Id) + 1);
         H := Mix (H, Cross_Unit_Final_Context_Kind'Pos (C.Kind) + 1);
         H := Mix (H, Cross_Unit_Dependency_State'Pos (C.Dependency) + 1);
         H := Mix (H, Natural (C.Node) + 1);
         H := Mix (H, Image_Hash (To_String (C.Unit_Name)));
         H := Mix (H, Image_Hash (To_String (C.Dependency_Name)));
         H := Mix (H, C.Source_Fingerprint + 1);
         H := Mix (H, C.Closure_Fingerprint + 1);
         H := Mix (H, C.Consumer_Fingerprint + 1);
      end loop;
      return H;
   end Fingerprint;

   function Build (Contexts : Cross_Unit_Final_Context_Model) return Cross_Unit_Final_Model is
      Model  : Cross_Unit_Final_Model;
      Next   : Cross_Unit_Final_Row_Id := 1;
      Status : Cross_Unit_Final_Status;
      Row    : Cross_Unit_Final_Info;
   begin
      for C of Contexts.Contexts loop
         Status := First_Blocker (C);
         Row :=
           (Id => Next,
            Context => C.Id,
            Kind => C.Kind,
            Dependency => C.Dependency,
            Status => Status,
            Node => C.Node,
            Unit_Name => C.Unit_Name,
            Dependency_Name => C.Dependency_Name,
            Message => Message_For (Status),
            Detail => To_Unbounded_String (Cross_Unit_Final_Status'Image (Status)),
            Source_Fingerprint => C.Source_Fingerprint,
            Closure_Fingerprint => C.Closure_Fingerprint,
            Consumer_Fingerprint => C.Consumer_Fingerprint,
            Fingerprint => 0);
         Row.Fingerprint := Fingerprint_For (Row);
         Model.Rows.Append (Row);
         Model.Model_Fingerprint := Mix (Model.Model_Fingerprint, Row.Fingerprint);
         Next := Next + 1;
      end loop;
      return Model;
   end Build;

   function Row_Count (Model : Cross_Unit_Final_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At (Model : Cross_Unit_Final_Model; Index : Positive) return Cross_Unit_Final_Info is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function First_For_Node (Model : Cross_Unit_Final_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Cross_Unit_Final_Info is
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status (Model : Cross_Unit_Final_Model; Status : Cross_Unit_Final_Status) return Cross_Unit_Final_Set is
      Result : Cross_Unit_Final_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Status;

   function Rows_For_Kind (Model : Cross_Unit_Final_Model; Kind : Cross_Unit_Final_Context_Kind) return Cross_Unit_Final_Set is
      Result : Cross_Unit_Final_Set;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Kind;

   function Rows_For_Unit (Model : Cross_Unit_Final_Model; Unit_Name : String) return Cross_Unit_Final_Set is
      Result : Cross_Unit_Final_Set;
   begin
      for Row of Model.Rows loop
         if Ada.Characters.Handling.To_Lower (To_String (Row.Unit_Name)) =
            Ada.Characters.Handling.To_Lower (Unit_Name)
         then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Unit;

   function Set_Count (Set : Cross_Unit_Final_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Set_Count;

   function Set_At (Set : Cross_Unit_Final_Set; Index : Positive) return Cross_Unit_Final_Info is
   begin
      return Set.Rows.Element (Index);
   end Set_At;

   function Count_Status (Model : Cross_Unit_Final_Model; Status : Cross_Unit_Final_Status) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind (Model : Cross_Unit_Final_Model; Kind : Cross_Unit_Final_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Count_Where (Model : Cross_Unit_Final_Model; Predicate : access function (S : Cross_Unit_Final_Status) return Boolean) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Predicate (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Where;

   function Legal_Count (Model : Cross_Unit_Final_Model) return Natural is
   begin
      return Count_Where (Model, Is_Legal'Access);
   end Legal_Count;

   function Error_Count (Model : Cross_Unit_Final_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if not Is_Legal (Row.Status) and then not Is_Indeterminate (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Error_Count;

   function Dependency_Error_Count (Model : Cross_Unit_Final_Model) return Natural is begin return Count_Where (Model, Is_Dependency_Error'Access); end;
   function View_Barrier_Count (Model : Cross_Unit_Final_Model) return Natural is begin return Count_Where (Model, Is_View_Barrier'Access); end;
   function Generic_Error_Count (Model : Cross_Unit_Final_Model) return Natural is begin return Count_Where (Model, Is_Generic_Error'Access); end;
   function Representation_Error_Count (Model : Cross_Unit_Final_Model) return Natural is begin return Count_Where (Model, Is_Representation_Error'Access); end;
   function Elaboration_Error_Count (Model : Cross_Unit_Final_Model) return Natural is begin return Count_Where (Model, Is_Elaboration_Error'Access); end;
   function Tasking_Error_Count (Model : Cross_Unit_Final_Model) return Natural is begin return Count_Where (Model, Is_Tasking_Error'Access); end;
   function Type_Access_Discriminant_Error_Count (Model : Cross_Unit_Final_Model) return Natural is begin return Count_Where (Model, Is_Type_Access_Discriminant_Error'Access); end;
   function Contract_Dataflow_Error_Count (Model : Cross_Unit_Final_Model) return Natural is begin return Count_Where (Model, Is_Contract_Dataflow_Error'Access); end;
   function Completion_Visibility_Exception_Error_Count (Model : Cross_Unit_Final_Model) return Natural is begin return Count_Where (Model, Is_Completion_Visibility_Exception_Error'Access); end;
   function Coverage_Error_Count (Model : Cross_Unit_Final_Model) return Natural is begin return Count_Where (Model, Is_Coverage_Error'Access); end;
   function Indeterminate_Count (Model : Cross_Unit_Final_Model) return Natural is begin return Count_Where (Model, Is_Indeterminate'Access); end;

   function Fingerprint (Model : Cross_Unit_Final_Model) return Natural is
   begin
      return Model.Model_Fingerprint;
   end Fingerprint;

   function Is_Legal (Status : Cross_Unit_Final_Status) return Boolean is
   begin
      return Status in Cross_Unit_Final_Accepted .. Cross_Unit_Final_Tasking_Protected_Accepted;
   end Is_Legal;

   function Is_Dependency_Error (Status : Cross_Unit_Final_Status) return Boolean is
   begin
      return Status in Cross_Unit_Final_Missing_Dependency | Cross_Unit_Final_Ambiguous_Dependency |
                       Cross_Unit_Final_Dependency_Overflow | Cross_Unit_Final_Stale_Dependency;
   end Is_Dependency_Error;

   function Is_View_Barrier (Status : Cross_Unit_Final_Status) return Boolean is
   begin
      return Status in Cross_Unit_Final_Limited_View_Barrier | Cross_Unit_Final_Private_View_Barrier |
                       Cross_Unit_Final_Child_Visibility_Blocker | Cross_Unit_Final_Separate_Body_Blocker;
   end Is_View_Barrier;

   function Is_Generic_Error (Status : Cross_Unit_Final_Status) return Boolean is
   begin
      return Status in Cross_Unit_Final_Generic_Body_Unavailable | Cross_Unit_Final_Generic_Backmapping_Blocker;
   end Is_Generic_Error;

   function Is_Representation_Error (Status : Cross_Unit_Final_Status) return Boolean is
   begin
      return Status in Cross_Unit_Final_Representation_Target_Blocker | Cross_Unit_Final_Representation_Freezing_Blocker;
   end Is_Representation_Error;

   function Is_Elaboration_Error (Status : Cross_Unit_Final_Status) return Boolean is
   begin
      return Status = Cross_Unit_Final_Elaboration_Dependence_Blocker;
   end Is_Elaboration_Error;

   function Is_Tasking_Error (Status : Cross_Unit_Final_Status) return Boolean is
   begin
      return Status = Cross_Unit_Final_Tasking_Protected_Final_Effect_Blocker;
   end Is_Tasking_Error;

   function Is_Type_Access_Discriminant_Error (Status : Cross_Unit_Final_Status) return Boolean is
   begin
      return Status in Cross_Unit_Final_Overload_Type_Edge_Blocker |
                       Cross_Unit_Final_Dispatching_Inherited_Primitive_Blocker |
                       Cross_Unit_Final_Accessibility_Lifetime_Blocker |
                       Cross_Unit_Final_Discriminant_Variant_Blocker;
   end Is_Type_Access_Discriminant_Error;

   function Is_Contract_Dataflow_Error (Status : Cross_Unit_Final_Status) return Boolean is
   begin
      return Status in Cross_Unit_Final_Predicate_Invariant_Blocker |
                       Cross_Unit_Final_Contract_Dataflow_Blocker |
                       Cross_Unit_Final_Refined_Global_Depends_Blocker;
   end Is_Contract_Dataflow_Error;

   function Is_Completion_Visibility_Exception_Error (Status : Cross_Unit_Final_Status) return Boolean is
   begin
      return Status in Cross_Unit_Final_Body_Spec_Completion_Blocker |
                       Cross_Unit_Final_Exception_Finalization_Blocker |
                       Cross_Unit_Final_Renaming_Alias_Visibility_Blocker;
   end Is_Completion_Visibility_Exception_Error;

   function Is_Coverage_Error (Status : Cross_Unit_Final_Status) return Boolean is
   begin
      return Status in Cross_Unit_Final_AST_Repair_Blocker | Cross_Unit_Final_Coverage_Gate_Blocker |
                       Cross_Unit_Final_Integrated_Closure_Blocker | Cross_Unit_Final_Multiple_Blockers;
   end Is_Coverage_Error;

   function Is_Indeterminate (Status : Cross_Unit_Final_Status) return Boolean is
   begin
      return Status = Cross_Unit_Final_Indeterminate;
   end Is_Indeterminate;

end Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality;
