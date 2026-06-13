with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Discriminant_Generic_Representation_Consumer_Legality is


   use type Disc.Discriminant_Legality_Id;
   use type Gen_Rep.Generic_Replay_Representation_Row_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   function Mix (Left, Right : Natural) return Natural is
      type Hash_Value is mod 2 ** 32;
      Mixed : constant Hash_Value :=
        Hash_Value (Left) * 16#01000193# + Hash_Value (Right) + 16#9E3779B9#;
   begin
      return Natural (Mixed mod Hash_Value (2_147_483_647));
   end Mix;

   function Is_Disc_Legal (Status : Disc.Discriminant_Legality_Status) return Boolean is
   begin
      case Status is
         when Disc.Discriminant_Legality_Legal_Constrained_Record |
              Disc.Discriminant_Legality_Legal_Unconstrained_With_Defaults |
              Disc.Discriminant_Legality_Legal_Discriminant_Default |
              Disc.Discriminant_Legality_Legal_Variant_Presence |
              Disc.Discriminant_Legality_Legal_Aggregate_Discriminants |
              Disc.Discriminant_Legality_Legal_Assignment_Check |
              Disc.Discriminant_Legality_Legal_Conversion_Check |
              Disc.Discriminant_Legality_Legal_Return_Check |
              Disc.Discriminant_Legality_Legal_Allocator_Check |
              Disc.Discriminant_Legality_Legal_Generic_Actual_Check =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Disc_Legal;

   function Is_Legal (Status : Discriminant_Generic_Status) return Boolean is
   begin
      case Status is
         when Discriminant_Generic_Legal_Record_Type_Accepted |
              Discriminant_Generic_Legal_Discriminant_Constraint_Accepted |
              Discriminant_Generic_Legal_Discriminant_Default_Accepted |
              Discriminant_Generic_Legal_Variant_Part_Accepted |
              Discriminant_Generic_Legal_Record_Aggregate_Accepted |
              Discriminant_Generic_Legal_Assignment_Accepted |
              Discriminant_Generic_Legal_Conversion_Accepted |
              Discriminant_Generic_Legal_Return_Accepted |
              Discriminant_Generic_Legal_Allocator_Accepted |
              Discriminant_Generic_Legal_Generic_Actual_Accepted |
              Discriminant_Generic_Legal_Private_Full_View_Accepted |
              Discriminant_Generic_Legal_Generic_Replay_Accepted |
              Discriminant_Generic_Legal_Representation_Clause_Accepted |
              Discriminant_Generic_Legal_Record_Layout_Accepted |
              Discriminant_Generic_Legal_Freezing_Effect_Accepted =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Legal;

   function Is_Discriminant_Error (Status : Discriminant_Generic_Status) return Boolean is
   begin
      return Status in Discriminant_Generic_Missing_Discriminant_Constraint |
                       Discriminant_Generic_Duplicate_Discriminant_Constraint |
                       Discriminant_Generic_Discriminant_Type_Mismatch |
                       Discriminant_Generic_Default_Not_Static |
                       Discriminant_Generic_Default_Out_Of_Range |
                       Discriminant_Generic_Default_Depends_On_Later_Discriminant |
                       Discriminant_Generic_Unconstrained_Record_Without_Defaults |
                       Discriminant_Generic_Constrained_Object_Discriminant_Changed |
                       Discriminant_Generic_Assignment_Discriminant_Mismatch |
                       Discriminant_Generic_Conversion_Discriminant_Mismatch |
                       Discriminant_Generic_Return_Discriminant_Mismatch |
                       Discriminant_Generic_Allocator_Discriminant_Mismatch |
                       Discriminant_Generic_Generic_Actual_Discriminant_Mismatch |
                       Discriminant_Generic_Private_Full_View_Mismatch |
                       Discriminant_Generic_Linked_Record_Aggregate_Error |
                       Discriminant_Generic_Linked_Assignment_Error |
                       Discriminant_Generic_Linked_Conversion_Error |
                       Discriminant_Generic_Linked_Return_Error |
                       Discriminant_Generic_Linked_Generic_Replay_Error;
   end Is_Discriminant_Error;

   function Is_Variant_Error (Status : Discriminant_Generic_Status) return Boolean is
   begin
      return Status in Discriminant_Generic_Variant_Missing_For_Value |
                       Discriminant_Generic_Variant_Forbidden_For_Value |
                       Discriminant_Generic_Variant_Choice_Overlap |
                       Discriminant_Generic_Variant_Choice_Coverage_Gap;
   end Is_Variant_Error;

   function Is_Generic_Representation_Error (Status : Discriminant_Generic_Status) return Boolean is
   begin
      return Status in Discriminant_Generic_Generic_Replay_Error |
                       Discriminant_Generic_Generic_Representation_Error |
                       Discriminant_Generic_Representation_Flow_Global_Error |
                       Discriminant_Generic_Representation_Flow_Depends_Error |
                       Discriminant_Generic_Representation_Flow_Propagation_Error |
                       Discriminant_Generic_Representation_Flow_Coverage_Blocker |
                       Discriminant_Generic_Representation_Flow_Tasking_Error |
                       Discriminant_Generic_Multiple_Generic_Representation_Blockers;
   end Is_Generic_Representation_Error;

   function Legal_Status_For_Kind
     (Kind : Discriminant_Generic_Context_Kind) return Discriminant_Generic_Status is
   begin
      case Kind is
         when Discriminant_Generic_Record_Type =>
            return Discriminant_Generic_Legal_Record_Type_Accepted;
         when Discriminant_Generic_Discriminant_Constraint =>
            return Discriminant_Generic_Legal_Discriminant_Constraint_Accepted;
         when Discriminant_Generic_Discriminant_Default =>
            return Discriminant_Generic_Legal_Discriminant_Default_Accepted;
         when Discriminant_Generic_Variant_Part =>
            return Discriminant_Generic_Legal_Variant_Part_Accepted;
         when Discriminant_Generic_Record_Aggregate =>
            return Discriminant_Generic_Legal_Record_Aggregate_Accepted;
         when Discriminant_Generic_Assignment =>
            return Discriminant_Generic_Legal_Assignment_Accepted;
         when Discriminant_Generic_Conversion =>
            return Discriminant_Generic_Legal_Conversion_Accepted;
         when Discriminant_Generic_Return =>
            return Discriminant_Generic_Legal_Return_Accepted;
         when Discriminant_Generic_Allocator =>
            return Discriminant_Generic_Legal_Allocator_Accepted;
         when Discriminant_Generic_Generic_Actual =>
            return Discriminant_Generic_Legal_Generic_Actual_Accepted;
         when Discriminant_Generic_Private_Full_View =>
            return Discriminant_Generic_Legal_Private_Full_View_Accepted;
         when Discriminant_Generic_Generic_Replay =>
            return Discriminant_Generic_Legal_Generic_Replay_Accepted;
         when Discriminant_Generic_Representation_Clause =>
            return Discriminant_Generic_Legal_Representation_Clause_Accepted;
         when Discriminant_Generic_Record_Layout =>
            return Discriminant_Generic_Legal_Record_Layout_Accepted;
         when Discriminant_Generic_Freezing_Effect =>
            return Discriminant_Generic_Legal_Freezing_Effect_Accepted;
         when others =>
            return Discriminant_Generic_Indeterminate;
      end case;
   end Legal_Status_For_Kind;

   function Status_From_Discriminant
     (Status : Disc.Discriminant_Legality_Status) return Discriminant_Generic_Status is
   begin
      case Status is
         when Disc.Discriminant_Legality_Missing_Discriminant_Constraint =>
            return Discriminant_Generic_Missing_Discriminant_Constraint;
         when Disc.Discriminant_Legality_Duplicate_Discriminant_Constraint =>
            return Discriminant_Generic_Duplicate_Discriminant_Constraint;
         when Disc.Discriminant_Legality_Discriminant_Type_Mismatch =>
            return Discriminant_Generic_Discriminant_Type_Mismatch;
         when Disc.Discriminant_Legality_Default_Not_Static =>
            return Discriminant_Generic_Default_Not_Static;
         when Disc.Discriminant_Legality_Default_Out_Of_Range =>
            return Discriminant_Generic_Default_Out_Of_Range;
         when Disc.Discriminant_Legality_Default_Depends_On_Later_Discriminant =>
            return Discriminant_Generic_Default_Depends_On_Later_Discriminant;
         when Disc.Discriminant_Legality_Unconstrained_Record_Without_Defaults =>
            return Discriminant_Generic_Unconstrained_Record_Without_Defaults;
         when Disc.Discriminant_Legality_Constrained_Object_Discriminant_Changed =>
            return Discriminant_Generic_Constrained_Object_Discriminant_Changed;
         when Disc.Discriminant_Legality_Assignment_Discriminant_Mismatch =>
            return Discriminant_Generic_Assignment_Discriminant_Mismatch;
         when Disc.Discriminant_Legality_Conversion_Discriminant_Mismatch =>
            return Discriminant_Generic_Conversion_Discriminant_Mismatch;
         when Disc.Discriminant_Legality_Return_Discriminant_Mismatch =>
            return Discriminant_Generic_Return_Discriminant_Mismatch;
         when Disc.Discriminant_Legality_Allocator_Discriminant_Mismatch =>
            return Discriminant_Generic_Allocator_Discriminant_Mismatch;
         when Disc.Discriminant_Legality_Generic_Actual_Discriminant_Mismatch =>
            return Discriminant_Generic_Generic_Actual_Discriminant_Mismatch;
         when Disc.Discriminant_Legality_Variant_Missing_For_Value =>
            return Discriminant_Generic_Variant_Missing_For_Value;
         when Disc.Discriminant_Legality_Variant_Forbidden_For_Value =>
            return Discriminant_Generic_Variant_Forbidden_For_Value;
         when Disc.Discriminant_Legality_Variant_Choice_Overlap =>
            return Discriminant_Generic_Variant_Choice_Overlap;
         when Disc.Discriminant_Legality_Variant_Choice_Coverage_Gap =>
            return Discriminant_Generic_Variant_Choice_Coverage_Gap;
         when Disc.Discriminant_Legality_Private_Full_View_Mismatch =>
            return Discriminant_Generic_Private_Full_View_Mismatch;
         when Disc.Discriminant_Legality_Linked_Record_Aggregate_Error =>
            return Discriminant_Generic_Linked_Record_Aggregate_Error;
         when Disc.Discriminant_Legality_Linked_Assignment_Error =>
            return Discriminant_Generic_Linked_Assignment_Error;
         when Disc.Discriminant_Legality_Linked_Conversion_Error =>
            return Discriminant_Generic_Linked_Conversion_Error;
         when Disc.Discriminant_Legality_Linked_Return_Error =>
            return Discriminant_Generic_Linked_Return_Error;
         when Disc.Discriminant_Legality_Linked_Generic_Replay_Error =>
            return Discriminant_Generic_Linked_Generic_Replay_Error;
         when Disc.Discriminant_Legality_Coverage_Gate_Blocker =>
            return Discriminant_Generic_Coverage_Gate_Blocker;
         when Disc.Discriminant_Legality_Multiple_Blockers =>
            return Discriminant_Generic_Multiple_Discriminant_Blockers;
         when Disc.Discriminant_Legality_Indeterminate |
              Disc.Discriminant_Legality_Not_Checked =>
            return Discriminant_Generic_Indeterminate;
         when others =>
            return Discriminant_Generic_Multiple_Discriminant_Blockers;
      end case;
   end Status_From_Discriminant;

   function Status_From_Generic_Representation
     (Status : Gen_Rep.Generic_Replay_Representation_Status) return Discriminant_Generic_Status is
   begin
      if Gen_Rep.Is_Global_Error (Status) then
         return Discriminant_Generic_Representation_Flow_Global_Error;
      elsif Gen_Rep.Is_Depends_Error (Status) then
         return Discriminant_Generic_Representation_Flow_Depends_Error;
      elsif Gen_Rep.Is_Propagation_Error (Status) then
         return Discriminant_Generic_Representation_Flow_Propagation_Error;
      end if;

      case Status is
         when Gen_Rep.Generic_Replay_Representation_Replay_Mapping_Error |
              Gen_Rep.Generic_Replay_Representation_Replay_Expansion_Error |
              Gen_Rep.Generic_Replay_Representation_Replay_Overload_Error |
              Gen_Rep.Generic_Replay_Representation_Replay_Flow_Error |
              Gen_Rep.Generic_Replay_Representation_Replay_Predicate_Error |
              Gen_Rep.Generic_Replay_Representation_Replay_Accessibility_Error |
              Gen_Rep.Generic_Replay_Representation_Replay_Representation_Error |
              Gen_Rep.Generic_Replay_Representation_Replay_Coverage_Gate_Blocker |
              Gen_Rep.Generic_Replay_Representation_Base_Replay_Error =>
            return Discriminant_Generic_Generic_Replay_Error;
         when Gen_Rep.Generic_Replay_Representation_Missing_Representation_Flow_Row |
              Gen_Rep.Generic_Replay_Representation_Base_Representation_Flow_Error |
              Gen_Rep.Generic_Replay_Representation_Base_Freezing_Error =>
            return Discriminant_Generic_Generic_Representation_Error;
         when Gen_Rep.Generic_Replay_Representation_Coverage_Feedback_Blocker =>
            return Discriminant_Generic_Representation_Flow_Coverage_Blocker;
         when Gen_Rep.Generic_Replay_Representation_Base_Tasking_Effect_Error =>
            return Discriminant_Generic_Representation_Flow_Tasking_Error;
         when Gen_Rep.Generic_Replay_Representation_Multiple_Representation_Flow_Blockers =>
            return Discriminant_Generic_Multiple_Generic_Representation_Blockers;
         when Gen_Rep.Generic_Replay_Representation_Representation_Flow_Indeterminate |
              Gen_Rep.Generic_Replay_Representation_Indeterminate |
              Gen_Rep.Generic_Replay_Representation_Not_Checked =>
            return Discriminant_Generic_Indeterminate;
         when others =>
            return Discriminant_Generic_Generic_Representation_Error;
      end case;
   end Status_From_Generic_Representation;

   function Status_For (Info : Discriminant_Generic_Context_Info) return Discriminant_Generic_Status is
   begin
      if Info.Discriminant_Matches > 1 then
         return Discriminant_Generic_Multiple_Discriminant_Blockers;
      elsif Info.Discriminant_Row = Disc.No_Discriminant_Legality then
         return Discriminant_Generic_Missing_Discriminant_Row;
      elsif not Is_Disc_Legal (Info.Discriminant_Status) then
         return Status_From_Discriminant (Info.Discriminant_Status);
      elsif Info.Generic_Representation_Matches > 1 then
         return Discriminant_Generic_Multiple_Generic_Representation_Blockers;
      elsif Info.Generic_Representation_Row = Gen_Rep.No_Generic_Replay_Representation_Row then
         return Discriminant_Generic_Missing_Generic_Representation_Row;
      elsif Gen_Rep.Is_Legal (Info.Generic_Representation_Status) then
         return Legal_Status_For_Kind (Info.Kind);
      else
         return Status_From_Generic_Representation (Info.Generic_Representation_Status);
      end if;
   end Status_For;

   function Row_Fingerprint (Info : Discriminant_Generic_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Discriminant_Generic_Context_Kind'Pos (Info.Kind) + 1);
      H := Mix (H, Discriminant_Generic_Status'Pos (Info.Status) + 1);
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Natural (Info.Discriminant_Row) + 1);
      H := Mix (H, Disc.Discriminant_Legality_Status'Pos (Info.Discriminant_Status) + 1);
      H := Mix (H, Info.Discriminant_Matches + 1);
      H := Mix (H, Natural (Info.Generic_Representation_Row) + 1);
      H := Mix (H, Gen_Rep.Generic_Replay_Representation_Status'Pos (Info.Generic_Representation_Status) + 1);
      H := Mix (H, Info.Generic_Representation_Matches + 1);
      H := Mix (H, Info.Source_Fingerprint + 1);
      H := Mix (H, Info.Instance_Fingerprint + 1);
      return H;
   end Row_Fingerprint;

   function To_Row (Info : Discriminant_Generic_Context_Info) return Discriminant_Generic_Info is
      Status : constant Discriminant_Generic_Status := Status_For (Info);
      Row    : Discriminant_Generic_Info;
   begin
      Row.Id := Info.Id;
      Row.Context := Info.Id;
      Row.Kind := Info.Kind;
      Row.Status := Status;
      Row.Node := Info.Node;
      Row.Type_Name := Info.Type_Name;
      Row.Object_Name := Info.Object_Name;
      Row.Generic_Unit_Name := Info.Generic_Unit_Name;
      Row.Instance_Name := Info.Instance_Name;
      Row.Target_Name := Info.Target_Name;
      Row.Discriminant_Row := Info.Discriminant_Row;
      Row.Discriminant_Status := Info.Discriminant_Status;
      Row.Discriminant_Matches := Info.Discriminant_Matches;
      Row.Generic_Representation_Row := Info.Generic_Representation_Row;
      Row.Generic_Representation_Status := Info.Generic_Representation_Status;
      Row.Generic_Representation_Matches := Info.Generic_Representation_Matches;
      Row.Start_Line := Info.Start_Line;
      Row.Start_Column := Info.Start_Column;
      Row.End_Line := Info.End_Line;
      Row.End_Column := Info.End_Column;
      Row.Source_Fingerprint := Info.Source_Fingerprint;
      Row.Instance_Fingerprint := Info.Instance_Fingerprint;

      if Is_Legal (Status) then
         Row.Message := To_Unbounded_String ("discriminant/variant legality accepted for generic representation consumer");
         Row.Detail := To_Unbounded_String ("discriminant-dependent row and generic representation-flow row both allow a confident consumer result");
      elsif Status = Discriminant_Generic_Missing_Discriminant_Row then
         Row.Message := To_Unbounded_String ("missing discriminant-dependent legality row");
         Row.Detail := To_Unbounded_String ("consumer cannot treat discriminant/variant-dependent generic representation result as confident without discriminant legality evidence");
      elsif Status = Discriminant_Generic_Missing_Generic_Representation_Row then
         Row.Message := To_Unbounded_String ("missing generic replay representation-flow row");
         Row.Detail := To_Unbounded_String ("discriminant-dependent result cannot be consumed by generic representation path without matching replay/representation evidence");
      else
         Row.Message := To_Unbounded_String ("discriminant/variant blocker prevents confident generic representation consumer result");
         Row.Detail := To_Unbounded_String ("the row preserves the discriminant, variant, generic replay, or representation-flow blocker that must be resolved first");
      end if;

      Row.Fingerprint := Row_Fingerprint (Row);
      return Row;
   end To_Row;

   procedure Clear (Model : in out Discriminant_Generic_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Discriminant_Generic_Context_Model;
      Info  : Discriminant_Generic_Context_Info) is
   begin
      Model.Contexts.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id) + 1);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Node) + 1);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Source_Fingerprint + 1);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Instance_Fingerprint + 1);
   end Add_Context;

   function Context_Count (Model : Discriminant_Generic_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Discriminant_Generic_Context_Model;
      Index : Positive) return Discriminant_Generic_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Discriminant_Generic_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   procedure Accumulate (Model : in out Discriminant_Generic_Model; Row : Discriminant_Generic_Info) is
   begin
      Model.Items.Append (Row);
      if Is_Legal (Row.Status) then
         Model.Legal_Total := Model.Legal_Total + 1;
      else
         Model.Error_Total := Model.Error_Total + 1;
      end if;
      if Is_Discriminant_Error (Row.Status) then
         Model.Discriminant_Error_Total := Model.Discriminant_Error_Total + 1;
      end if;
      if Is_Variant_Error (Row.Status) then
         Model.Variant_Error_Total := Model.Variant_Error_Total + 1;
      end if;
      if Is_Generic_Representation_Error (Row.Status) then
         Model.Generic_Representation_Error_Total := Model.Generic_Representation_Error_Total + 1;
      end if;
      if Row.Status in Discriminant_Generic_Representation_Flow_Global_Error |
                       Discriminant_Generic_Representation_Flow_Depends_Error |
                       Discriminant_Generic_Representation_Flow_Propagation_Error |
                       Discriminant_Generic_Representation_Flow_Tasking_Error then
         Model.Flow_Error_Total := Model.Flow_Error_Total + 1;
      end if;
      if Row.Status in Discriminant_Generic_Coverage_Gate_Blocker |
                       Discriminant_Generic_Representation_Flow_Coverage_Blocker then
         Model.Coverage_Error_Total := Model.Coverage_Error_Total + 1;
      end if;
      if Row.Status = Discriminant_Generic_Indeterminate then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Row.Fingerprint + 1);
   end Accumulate;

   function Build
     (Contexts : Discriminant_Generic_Context_Model) return Discriminant_Generic_Model is
      Result : Discriminant_Generic_Model;
   begin
      for I in 1 .. Context_Count (Contexts) loop
         Accumulate (Result, To_Row (Context_At (Contexts, I)));
      end loop;
      return Result;
   end Build;

   function Row_Count (Model : Discriminant_Generic_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Row_Count;

   function Row_At
     (Model : Discriminant_Generic_Model;
      Index : Positive) return Discriminant_Generic_Info is
   begin
      return Model.Items.Element (Index);
   end Row_At;

   function First_For_Node
     (Model : Discriminant_Generic_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Discriminant_Generic_Info is
   begin
      for Row of Model.Items loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Discriminant_Generic_Model;
      Status : Discriminant_Generic_Status) return Discriminant_Generic_Set is
      Result : Discriminant_Generic_Set;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then
            Result.Items.Append (Row);
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, Row.Fingerprint + 1);
         end if;
      end loop;
      return Result;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Discriminant_Generic_Model;
      Kind  : Discriminant_Generic_Context_Kind) return Discriminant_Generic_Set is
      Result : Discriminant_Generic_Set;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then
            Result.Items.Append (Row);
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, Row.Fingerprint + 1);
         end if;
      end loop;
      return Result;
   end Rows_For_Kind;

   function Rows_For_Instance
     (Model : Discriminant_Generic_Model;
      Name  : String) return Discriminant_Generic_Set is
      Result : Discriminant_Generic_Set;
   begin
      for Row of Model.Items loop
         if To_String (Row.Instance_Name) = Name then
            Result.Items.Append (Row);
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, Row.Fingerprint + 1);
         end if;
      end loop;
      return Result;
   end Rows_For_Instance;

   function Set_Count (Set : Discriminant_Generic_Set) return Natural is
   begin
      return Natural (Set.Items.Length);
   end Set_Count;

   function Set_At
     (Set   : Discriminant_Generic_Set;
      Index : Positive) return Discriminant_Generic_Info is
   begin
      return Set.Items.Element (Index);
   end Set_At;

   function Count_Status
     (Model  : Discriminant_Generic_Model;
      Status : Discriminant_Generic_Status) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind
     (Model : Discriminant_Generic_Model;
      Kind  : Discriminant_Generic_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : Discriminant_Generic_Model) return Natural is
   begin
      return Model.Legal_Total;
   end Legal_Count;

   function Error_Count (Model : Discriminant_Generic_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Discriminant_Error_Count (Model : Discriminant_Generic_Model) return Natural is
   begin
      return Model.Discriminant_Error_Total;
   end Discriminant_Error_Count;

   function Variant_Error_Count (Model : Discriminant_Generic_Model) return Natural is
   begin
      return Model.Variant_Error_Total;
   end Variant_Error_Count;

   function Generic_Representation_Error_Count (Model : Discriminant_Generic_Model) return Natural is
   begin
      return Model.Generic_Representation_Error_Total;
   end Generic_Representation_Error_Count;

   function Flow_Error_Count (Model : Discriminant_Generic_Model) return Natural is
   begin
      return Model.Flow_Error_Total;
   end Flow_Error_Count;

   function Coverage_Error_Count (Model : Discriminant_Generic_Model) return Natural is
   begin
      return Model.Coverage_Error_Total;
   end Coverage_Error_Count;

   function Indeterminate_Count (Model : Discriminant_Generic_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Discriminant_Generic_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Discriminant_Generic_Representation_Consumer_Legality;
