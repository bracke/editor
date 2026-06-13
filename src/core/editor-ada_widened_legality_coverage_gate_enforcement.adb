with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement is

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Gates.Semantic_Conclusion_Kind;

   function Mix (Left, Right : Natural) return Natural is
      Hash : constant Long_Long_Integer :=
        (Long_Long_Integer (Left) * 149 + Long_Long_Integer (Right) * 31 + 1137)
        mod 2_147_483_647;
   begin
      return Natural (Hash);
   end Mix;

   function Node_Slot (Node : Editor.Ada_Syntax_Tree.Node_Id) return Natural is
   begin
      return Natural (Node);
   exception
      when Constraint_Error => return 0;
   end Node_Slot;

   function Engine_For
     (Conclusion : Gates.Semantic_Conclusion_Kind;
      Consumer   : Audit.Semantic_Consumer_Family)
      return Widened_Legality_Engine is
   begin
      case Conclusion is
         when Gates.Conclusion_Assignment =>
            return Engine_Assignment;
         when Gates.Conclusion_Return =>
            return Engine_Return;
         when Gates.Conclusion_Conversion |
              Gates.Conclusion_Aggregate =>
            return Engine_Conversion_Access_Aggregate;
         when Gates.Conclusion_Call |
              Gates.Conclusion_Overload =>
            return Engine_Call_Overload;
         when Gates.Conclusion_Staticness =>
            return Engine_Staticness_Range_Predicate;
         when Gates.Conclusion_Accessibility =>
            return Engine_Accessibility_Lifetime;
         when Gates.Conclusion_Contract =>
            return Engine_Contract_Aspect;
         when Gates.Conclusion_Dataflow =>
            return Engine_Dataflow_Global_Depends;
         when Gates.Conclusion_Generic_Instance =>
            return Engine_Generic_Instance_Body;
         when Gates.Conclusion_Record_Variant =>
            return Engine_Record_Variant_Aggregate;
         when Gates.Conclusion_Elaboration =>
            return Engine_Elaboration;
         when Gates.Conclusion_Tasking_Protected =>
            return Engine_Tasking_Protected;
         when Gates.Conclusion_Representation =>
            return Engine_Representation_Freezing;
         when Gates.Conclusion_Exception_Finalization =>
            return Engine_Exception_Finalization;
         when Gates.Conclusion_Integrated_Closure =>
            return Engine_Integrated_Closure;
         when Gates.Conclusion_Unknown =>
            case Consumer is
               when Audit.Consumer_Assignment =>
                  return Engine_Assignment;
               when Audit.Consumer_Return =>
                  return Engine_Return;
               when Audit.Consumer_Conversion_Access_Aggregate |
                    Audit.Consumer_Predicate_Invariant_Use_Site =>
                  return Engine_Conversion_Access_Aggregate;
               when Audit.Consumer_Record_Variant_Aggregate =>
                  return Engine_Record_Variant_Aggregate;
               when Audit.Consumer_Overload |
                    Audit.Consumer_Overload_Preference |
                    Audit.Consumer_Expression_Types =>
                  return Engine_Call_Overload;
               when Audit.Consumer_Staticness_Range_Predicate =>
                  return Engine_Staticness_Range_Predicate;
               when Audit.Consumer_Accessibility_Lifetime |
                    Audit.Consumer_Accessibility_Precision =>
                  return Engine_Accessibility_Lifetime;
               when Audit.Consumer_Contract_Aspect =>
                  return Engine_Contract_Aspect;
               when Audit.Consumer_Dataflow_Global_Depends |
                    Audit.Consumer_Definite_Initialization =>
                  return Engine_Dataflow_Global_Depends;
               when Audit.Consumer_Generic_Contracts |
                    Audit.Consumer_Generic_Instance_Body_Expansion =>
                  return Engine_Generic_Instance_Body;
               when Audit.Consumer_Elaboration_Dependence |
                    Audit.Consumer_Elaboration_Precision =>
                  return Engine_Elaboration;
               when Audit.Consumer_Tasking_Protected |
                    Audit.Consumer_Tasking_Protected_Precision =>
                  return Engine_Tasking_Protected;
               when Audit.Consumer_Representation_Layout_Stream |
                    Audit.Consumer_Representation_Freezing_Precision =>
                  return Engine_Representation_Freezing;
               when Audit.Consumer_Exception_Finalization =>
                  return Engine_Exception_Finalization;
               when Audit.Consumer_Integrated_Closure |
                    Audit.Consumer_Cross_Unit_Closure =>
                  return Engine_Integrated_Closure;
               when others =>
                  return Engine_Unknown;
            end case;
      end case;
   end Engine_For;

   function Enforced_Status_For
     (Gated_Status : Gated.Gated_Result_Status)
      return Enforcement_Status is
   begin
      case Gated_Status is
         when Gated.Gated_Result_Not_Checked =>
            return Enforcement_Not_Checked;
         when Gated.Gated_Result_Confident =>
            return Enforcement_Confident_Result_Allowed;
         when Gated.Gated_Result_Degraded_Indeterminate =>
            return Enforcement_Degraded_To_Indeterminate;
         when Gated.Gated_Result_Legal_Suppressed =>
            return Enforcement_Legal_Result_Suppressed;
         when Gated.Gated_Result_Derived_Suppressed =>
            return Enforcement_Derived_Result_Suppressed;
         when Gated.Gated_Result_Cross_Unit_Required =>
            return Enforcement_Cross_Unit_Closure_Required;
         when Gated.Gated_Result_Parser_AST_Repair_Required =>
            return Enforcement_Parser_AST_Blocker;
         when Gated.Gated_Result_Metadata_Repair_Required =>
            return Enforcement_Metadata_Blocker;
         when Gated.Gated_Result_Consumer_Integration_Required =>
            return Enforcement_Consumer_Integration_Blocker;
         when Gated.Gated_Result_Blocked_Unsafe =>
            return Enforcement_Unsafe_Result_Blocked;
         when Gated.Gated_Result_Original_Error_Preserved =>
            return Enforcement_Original_Error_Preserved;
      end case;
   end Enforced_Status_For;

   function Message_For (Status : Enforcement_Status) return String is
   begin
      case Status is
         when Enforcement_Not_Checked =>
            return "coverage gate enforcement has not checked this semantic result";
         when Enforcement_Confident_Result_Allowed =>
            return "widened legality engine may keep the semantic result confident";
         when Enforcement_Original_Error_Preserved =>
            return "widened legality engine preserves the original semantic error";
         when Enforcement_Degraded_To_Indeterminate =>
            return "widened legality engine must degrade the result to indeterminate";
         when Enforcement_Cross_Unit_Closure_Required =>
            return "widened legality engine must require cross-unit closure";
         when Enforcement_Legal_Result_Suppressed =>
            return "widened legality engine must suppress a legal result";
         when Enforcement_Derived_Result_Suppressed =>
            return "widened legality engine must suppress a derived legal result";
         when Enforcement_Parser_AST_Blocker =>
            return "widened legality engine is blocked by parser or AST coverage";
         when Enforcement_Metadata_Blocker =>
            return "widened legality engine is blocked by semantic metadata coverage";
         when Enforcement_Consumer_Integration_Blocker =>
            return "widened legality engine is blocked by missing consumer integration";
         when Enforcement_Unsafe_Result_Blocked =>
            return "widened legality engine blocks an unsafe semantic result";
      end case;
   end Message_For;

   function Detail_For (Context : Enforcement_Context_Info; Status : Enforcement_Status) return String is
   begin
      return "engine=" & Widened_Legality_Engine'Image (Context.Engine) &
        "; enforcement=" & Enforcement_Status'Image (Status) &
        "; gated=" & Gated.Gated_Result_Status'Image (Context.Gated_Status) &
        "; conclusion=" & Gates.Semantic_Conclusion_Kind'Image (Context.Conclusion) &
        "; original=" & Gated.Original_Result_State'Image (Context.Original_State) &
        "; gate_action=" & Gates.Gate_Action'Image (Context.Gate_Action) &
        "; gate_status=" & Gates.Gate_Status'Image (Context.Gate_Status) &
        "; construct=" & Audit.Ada_Construct_Kind'Image (Context.Construct) &
        "; consumer=" & Audit.Semantic_Consumer_Family'Image (Context.Consumer) &
        "; semantic_row=" & Natural'Image (Context.Semantic_Row_Id);
   end Detail_For;

   function Row_Fingerprint (Row : Enforcement_Info) return Natural is
      H : Natural := Row.Source_Fingerprint;
   begin
      H := Mix (H, Natural (Row.Id));
      H := Mix (H, Widened_Legality_Engine'Pos (Row.Engine) + 1);
      H := Mix (H, Enforcement_Status'Pos (Row.Status) + 1);
      H := Mix (H, Natural (Row.Gated_Result_Id));
      H := Mix (H, Gates.Semantic_Conclusion_Kind'Pos (Row.Conclusion) + 1);
      H := Mix (H, Gated.Original_Result_State'Pos (Row.Original_State) + 1);
      H := Mix (H, Gated.Gated_Result_Status'Pos (Row.Gated_Status) + 1);
      H := Mix (H, Gates.Gate_Action'Pos (Row.Gate_Action) + 1);
      H := Mix (H, Audit.Ada_Construct_Kind'Pos (Row.Construct) + 1);
      H := Mix (H, Audit.Semantic_Consumer_Family'Pos (Row.Consumer) + 1);
      H := Mix (H, Node_Slot (Row.Node));
      H := Mix (H, Row.Semantic_Row_Id);
      H := Mix (H, Row.Start_Line);
      H := Mix (H, Row.Start_Column);
      return H;
   end Row_Fingerprint;

   function Build_Info (Context : Enforcement_Context_Info) return Enforcement_Info is
      Status : constant Enforcement_Status := Enforced_Status_For (Context.Gated_Status);
      Row    : Enforcement_Info;
   begin
      Row.Id := Context.Id;
      Row.Engine := Context.Engine;
      Row.Status := Status;
      Row.Gated_Result_Id := Context.Gated_Result_Id;
      Row.Conclusion := Context.Conclusion;
      Row.Original_State := Context.Original_State;
      Row.Gated_Status := Context.Gated_Status;
      Row.Gate_Status := Context.Gate_Status;
      Row.Gate_Action := Context.Gate_Action;
      Row.Construct := Context.Construct;
      Row.Consumer := Context.Consumer;
      Row.Node := Context.Node;
      Row.Parent_Node := Context.Parent_Node;
      Row.Semantic_Row_Id := Context.Semantic_Row_Id;
      Row.Construct_Name := Context.Construct_Name;
      Row.Normalized_Name := Context.Normalized_Name;
      Row.Message := To_Unbounded_String (Message_For (Status));
      Row.Detail := To_Unbounded_String (Detail_For (Context, Status));
      if Length (Context.Source_Message) > 0 then
         Row.Detail := Row.Detail & To_Unbounded_String ("; gated_message=") & Context.Source_Message;
      end if;
      if Length (Context.Source_Detail) > 0 then
         Row.Detail := Row.Detail & To_Unbounded_String ("; gated_detail=") & Context.Source_Detail;
      end if;
      Row.Source_Fingerprint := Context.Source_Fingerprint;
      Row.Start_Line := Context.Start_Line;
      Row.Start_Column := Context.Start_Column;
      Row.End_Line := Context.End_Line;
      Row.End_Column := Context.End_Column;
      Row.Fingerprint := Row_Fingerprint (Row);
      return Row;
   end Build_Info;

   procedure Clear (Model : in out Enforcement_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model   : in out Enforcement_Context_Model;
      Context : Enforcement_Context_Info) is
   begin
      Model.Items.Append (Context);
      Model.Fingerprint := Mix (Model.Fingerprint, Natural (Context.Id));
      Model.Fingerprint := Mix (Model.Fingerprint, Widened_Legality_Engine'Pos (Context.Engine) + 1);
      Model.Fingerprint := Mix (Model.Fingerprint, Gates.Semantic_Conclusion_Kind'Pos (Context.Conclusion) + 1);
      Model.Fingerprint := Mix (Model.Fingerprint, Gated.Gated_Result_Status'Pos (Context.Gated_Status) + 1);
      Model.Fingerprint := Mix (Model.Fingerprint, Gates.Gate_Action'Pos (Context.Gate_Action) + 1);
      Model.Fingerprint := Mix (Model.Fingerprint, Node_Slot (Context.Node));
      Model.Fingerprint := Mix (Model.Fingerprint, Context.Source_Fingerprint);
   end Add_Context;

   procedure Add_From_Gated_Result
     (Model : in out Enforcement_Context_Model;
      Row   : Gated.Gated_Result_Info)
   is
      Context : Enforcement_Context_Info;
   begin
      Context.Id := Enforcement_Row_Id (Natural (Row.Id));
      Context.Engine := Engine_For (Row.Conclusion, Row.Consumer);
      Context.Gated_Result_Id := Row.Id;
      Context.Conclusion := Row.Conclusion;
      Context.Original_State := Row.Original_State;
      Context.Gated_Status := Row.Status;
      Context.Gate_Status := Row.Gate_Status;
      Context.Gate_Action := Row.Gate_Action;
      Context.Construct := Row.Construct;
      Context.Consumer := Row.Consumer;
      Context.Node := Row.Node;
      Context.Parent_Node := Row.Parent_Node;
      Context.Semantic_Row_Id := Row.Semantic_Row_Id;
      Context.Construct_Name := Row.Construct_Name;
      Context.Normalized_Name := Row.Normalized_Name;
      Context.Source_Message := Row.Message;
      Context.Source_Detail := Row.Detail;
      Context.Source_Fingerprint := Row.Fingerprint;
      Context.Start_Line := Row.Start_Line;
      Context.Start_Column := Row.Start_Column;
      Context.End_Line := Row.End_Line;
      Context.End_Column := Row.End_Column;
      Add_Context (Model, Context);
   end Add_From_Gated_Result;

   function Build (Contexts : Enforcement_Context_Model) return Enforcement_Model is
      Model : Enforcement_Model;
   begin
      Model.Fingerprint := Mix (Contexts.Fingerprint, Natural (Contexts.Items.Length));
      for Context of Contexts.Items loop
         declare
            Row : constant Enforcement_Info := Build_Info (Context);
         begin
            Model.Items.Append (Row);
            Model.Fingerprint := Mix (Model.Fingerprint, Row.Fingerprint);
         end;
      end loop;
      return Model;
   end Build;

   function Build_From_Gated_Results
     (Results : Gated.Gated_Result_Model) return Enforcement_Model
   is
      Contexts : Enforcement_Context_Model;
   begin
      for Index in 1 .. Gated.Result_Count (Results) loop
         Add_From_Gated_Result (Contexts, Gated.Result_At (Results, Index));
      end loop;
      return Build (Contexts);
   end Build_From_Gated_Results;

   function Row_Count (Model : Enforcement_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Row_Count;

   function Row_At
     (Model : Enforcement_Model;
      Index : Positive) return Enforcement_Info is
   begin
      return Model.Items.Element (Index);
   end Row_At;

   function First_For_Node
     (Model : Enforcement_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Enforcement_Info is
   begin
      for Row of Model.Items loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Engine
     (Model  : Enforcement_Model;
      Engine : Widened_Legality_Engine) return Enforcement_Set
   is
      Set : Enforcement_Set;
   begin
      for Row of Model.Items loop
         if Row.Engine = Engine then
            Set.Items.Append (Row);
         end if;
      end loop;
      return Set;
   end Rows_For_Engine;

   function Rows_For_Status
     (Model  : Enforcement_Model;
      Status : Enforcement_Status) return Enforcement_Set
   is
      Set : Enforcement_Set;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then
            Set.Items.Append (Row);
         end if;
      end loop;
      return Set;
   end Rows_For_Status;

   function Rows_For_Conclusion
     (Model      : Enforcement_Model;
      Conclusion : Gates.Semantic_Conclusion_Kind) return Enforcement_Set
   is
      Set : Enforcement_Set;
   begin
      for Row of Model.Items loop
         if Row.Conclusion = Conclusion then
            Set.Items.Append (Row);
         end if;
      end loop;
      return Set;
   end Rows_For_Conclusion;

   function Set_Count (Set : Enforcement_Set) return Natural is
   begin
      return Natural (Set.Items.Length);
   end Set_Count;

   function Set_At
     (Set   : Enforcement_Set;
      Index : Positive) return Enforcement_Info is
   begin
      return Set.Items.Element (Index);
   end Set_At;

   function Count_Engine
     (Model  : Enforcement_Model;
      Engine : Widened_Legality_Engine) return Natural is
   begin
      return Set_Count (Rows_For_Engine (Model, Engine));
   end Count_Engine;

   function Count_Status
     (Model  : Enforcement_Model;
      Status : Enforcement_Status) return Natural is
   begin
      return Set_Count (Rows_For_Status (Model, Status));
   end Count_Status;

   function Count_Conclusion
     (Model      : Enforcement_Model;
      Conclusion : Gates.Semantic_Conclusion_Kind) return Natural is
   begin
      return Set_Count (Rows_For_Conclusion (Model, Conclusion));
   end Count_Conclusion;

   function Confident_Count (Model : Enforcement_Model) return Natural is
   begin
      return Count_Status (Model, Enforcement_Confident_Result_Allowed);
   end Confident_Count;

   function Preserved_Error_Count (Model : Enforcement_Model) return Natural is
   begin
      return Count_Status (Model, Enforcement_Original_Error_Preserved);
   end Preserved_Error_Count;

   function Degraded_Count (Model : Enforcement_Model) return Natural is
   begin
      return Count_Status (Model, Enforcement_Degraded_To_Indeterminate);
   end Degraded_Count;

   function Suppressed_Count (Model : Enforcement_Model) return Natural is
   begin
      return Count_Status (Model, Enforcement_Legal_Result_Suppressed) +
        Count_Status (Model, Enforcement_Derived_Result_Suppressed);
   end Suppressed_Count;

   function Repair_Blocker_Count (Model : Enforcement_Model) return Natural is
   begin
      return Count_Status (Model, Enforcement_Parser_AST_Blocker) +
        Count_Status (Model, Enforcement_Metadata_Blocker) +
        Count_Status (Model, Enforcement_Consumer_Integration_Blocker);
   end Repair_Blocker_Count;

   function Cross_Unit_Required_Count (Model : Enforcement_Model) return Natural is
   begin
      return Count_Status (Model, Enforcement_Cross_Unit_Closure_Required);
   end Cross_Unit_Required_Count;

   function Unsafe_Blocker_Count (Model : Enforcement_Model) return Natural is
   begin
      return Count_Status (Model, Enforcement_Legal_Result_Suppressed) +
        Count_Status (Model, Enforcement_Derived_Result_Suppressed) +
        Count_Status (Model, Enforcement_Parser_AST_Blocker) +
        Count_Status (Model, Enforcement_Metadata_Blocker) +
        Count_Status (Model, Enforcement_Consumer_Integration_Blocker) +
        Count_Status (Model, Enforcement_Unsafe_Result_Blocked);
   end Unsafe_Blocker_Count;

   function Fingerprint (Model : Enforcement_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;
