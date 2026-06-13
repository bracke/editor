with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Generic_Instance_Body_Semantic_Replay is

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Expansion.Generic_Body_Expansion_Status;
   use type Preference.Preference_Legality_Status;
   use type Flow_Graph.Flow_Effect_Graph_Status;
   use type Predicate_Propagation.Propagation_Status;
   use type Access_Precision.Accessibility_Precision_Status;
   use type Representation_Freezing.Representation_Freezing_Precision_Status;
   use type Gates.Enforcement_Status;

   function Hash_Text (Text : String) return Natural is
      Result : Natural := 0;
   begin
      for C of Text loop
         Result :=
           (Result * 131 + Character'Pos (Ada.Characters.Handling.To_Lower (C)) + 1)
           mod Natural'Last;
      end loop;
      return Result;
   end Hash_Text;

   function Mix (Left, Right : Natural) return Natural is
      type Hash_Value is mod 2 ** 32;
      Mixed : constant Hash_Value :=
        (Hash_Value (Left) * 16_777_619) xor
        (Hash_Value (Right) + 536_870_909);
   begin
      return Natural (Mixed mod Hash_Value (2_147_483_647));
   end Mix;

   function Status_Fingerprint (Status : Replay_Status) return Natural is
   begin
      return Replay_Status'Pos (Status) * 1_000_003;
   end Status_Fingerprint;

   function Normalize (Text : Unbounded_String) return String is
   begin
      return Ada.Characters.Handling.To_Lower (To_String (Text));
   end Normalize;

   function Expansion_Is_Error
     (Status : Expansion.Generic_Body_Expansion_Status) return Boolean is
   begin
      case Status is
         when Expansion.Generic_Body_Expansion_Not_Checked |
              Expansion.Generic_Body_Expansion_Legal_Substitution |
              Expansion.Generic_Body_Expansion_Legal_Default_Substitution |
              Expansion.Generic_Body_Expansion_Legal_Overload |
              Expansion.Generic_Body_Expansion_Legal_Accessibility |
              Expansion.Generic_Body_Expansion_Legal_Contract |
              Expansion.Generic_Body_Expansion_Legal_Dataflow |
              Expansion.Generic_Body_Expansion_Legal_Initialization |
              Expansion.Generic_Body_Expansion_Legal_Predicate_Invariant |
              Expansion.Generic_Body_Expansion_Legal_Representation =>
            return False;
         when others =>
            return True;
      end case;
   end Expansion_Is_Error;

   function Overload_Is_Error
     (Status : Preference.Preference_Legality_Status) return Boolean is
   begin
      case Status is
         when Preference.Preference_Legality_Not_Checked |
              Preference.Preference_Legality_Legal_Exact_Profile |
              Preference.Preference_Legality_Legal_Direct_Visibility_Preferred |
              Preference.Preference_Legality_Legal_Use_Visibility_Preferred |
              Preference.Preference_Legality_Legal_Expected_Type_Profile_Preferred |
              Preference.Preference_Legality_Legal_Primitive_Operator_Preferred |
              Preference.Preference_Legality_Legal_Dispatching_Primitive_Preferred |
              Preference.Preference_Legality_Legal_Universal_Integer_Preferred |
              Preference.Preference_Legality_Legal_Universal_Real_Preferred |
              Preference.Preference_Legality_Legal_Implicit_Conversion_Preferred |
              Preference.Preference_Legality_Legal_Class_Wide_Preferred |
              Preference.Preference_Legality_Legal_Access_Conversion_Preferred |
              Preference.Preference_Legality_Legal_Named_Actual_Profile_Preferred |
              Preference.Preference_Legality_Legal_Defaulted_Formal_Profile_Preferred =>
            return False;
         when others =>
            return True;
      end case;
   end Overload_Is_Error;

   function Flow_Is_Error
     (Status : Flow_Graph.Flow_Effect_Graph_Status) return Boolean is
   begin
      case Status is
         when Flow_Graph.Flow_Graph_Not_Checked |
              Flow_Graph.Flow_Graph_Legal_Read_Edge |
              Flow_Graph.Flow_Graph_Legal_Write_Edge |
              Flow_Graph.Flow_Graph_Legal_Read_Write_Edge |
              Flow_Graph.Flow_Graph_Legal_Depends_Edge |
              Flow_Graph.Flow_Graph_Legal_Call_Propagation |
              Flow_Graph.Flow_Graph_Legal_Generic_Substitution |
              Flow_Graph.Flow_Graph_Legal_Protected_State_Effect |
              Flow_Graph.Flow_Graph_Legal_Task_Activation_Effect |
              Flow_Graph.Flow_Graph_Legal_Refined_Global |
              Flow_Graph.Flow_Graph_Legal_Refined_Depends |
              Flow_Graph.Flow_Graph_Legal_Null_Effect =>
            return False;
         when others =>
            return True;
      end case;
   end Flow_Is_Error;

   function Predicate_Is_Error
     (Status : Predicate_Propagation.Propagation_Status) return Boolean is
   begin
      case Status is
         when Predicate_Propagation.Propagation_Not_Checked |
              Predicate_Propagation.Propagation_Legal_Static_Predicate_Preserved |
              Predicate_Propagation.Propagation_Legal_Dynamic_Predicate_Propagated |
              Predicate_Propagation.Propagation_Legal_Invariant_Preserved |
              Predicate_Propagation.Propagation_Legal_Dynamic_Invariant_Propagated |
              Predicate_Propagation.Propagation_Legal_Generic_Substitution_Propagated |
              Predicate_Propagation.Propagation_Legal_Derived_Invariant_Propagated |
              Predicate_Propagation.Propagation_Legal_Private_Full_View_Propagated |
              Predicate_Propagation.Propagation_Legal_Flow_Effect_Propagated =>
            return False;
         when others =>
            return True;
      end case;
   end Predicate_Is_Error;

   function Accessibility_Is_Error
     (Status : Access_Precision.Accessibility_Precision_Status) return Boolean is
   begin
      case Status is
         when Access_Precision.Accessibility_Precision_Not_Checked |
              Access_Precision.Accessibility_Precision_Legal_Static_Level |
              Access_Precision.Accessibility_Precision_Legal_Dynamic_Check |
              Access_Precision.Accessibility_Precision_Legal_Allocator_Master |
              Access_Precision.Accessibility_Precision_Legal_Return_Level |
              Access_Precision.Accessibility_Precision_Legal_Access_Discriminant |
              Access_Precision.Accessibility_Precision_Legal_Generic_Substitution |
              Access_Precision.Accessibility_Precision_Legal_Aggregate_Discriminant =>
            return False;
         when others =>
            return True;
      end case;
   end Accessibility_Is_Error;

   function Representation_Is_Error
     (Status : Representation_Freezing.Representation_Freezing_Precision_Status)
      return Boolean is
   begin
      case Status is
         when Representation_Freezing.Representation_Freezing_Precision_Not_Checked |
              Representation_Freezing.Representation_Freezing_Precision_Legal_Representation_Item |
              Representation_Freezing.Representation_Freezing_Precision_Legal_Aspect |
              Representation_Freezing.Representation_Freezing_Precision_Legal_Operational_Item |
              Representation_Freezing.Representation_Freezing_Precision_Legal_Stream_Attribute |
              Representation_Freezing.Representation_Freezing_Precision_Legal_Record_Layout |
              Representation_Freezing.Representation_Freezing_Precision_Legal_Generic_Instance_Effect |
              Representation_Freezing.Representation_Freezing_Precision_Legal_Private_Full_View |
              Representation_Freezing.Representation_Freezing_Precision_Legal_Implicit_Freezing =>
            return False;
         when others =>
            return True;
      end case;
   end Representation_Is_Error;

   function Gate_Is_Error (Status : Gates.Enforcement_Status) return Boolean is
   begin
      case Status is
         when Gates.Enforcement_Not_Checked |
              Gates.Enforcement_Confident_Result_Allowed |
              Gates.Enforcement_Original_Error_Preserved =>
            return False;
         when others =>
            return True;
      end case;
   end Gate_Is_Error;

   function Mapping_Blocker_Count (Context : Replay_Context_Info) return Natural is
      Count : Natural := 0;
   begin
      if not Context.Source_Mapping_Present then
         Count := Count + 1;
      end if;
      if not Context.Formal_Actual_Mapping_Present then
         Count := Count + 1;
      end if;
      if not Context.Diagnostic_Backmap_Present then
         Count := Count + 1;
      end if;
      return Count;
   end Mapping_Blocker_Count;

   function Count_Blockers (Context : Replay_Context_Info) return Natural is
      Count : Natural := Mapping_Blocker_Count (Context);
   begin
      if Expansion_Is_Error (Context.Expansion_Status) then
         Count := Count + 1;
      end if;
      if Overload_Is_Error (Context.Overload_Status) then
         Count := Count + 1;
      end if;
      if Flow_Is_Error (Context.Flow_Status) then
         Count := Count + 1;
      end if;
      if Predicate_Is_Error (Context.Predicate_Status) then
         Count := Count + 1;
      end if;
      if Accessibility_Is_Error (Context.Accessibility_Status) then
         Count := Count + 1;
      end if;
      if Representation_Is_Error (Context.Representation_Status) then
         Count := Count + 1;
      end if;
      if Gate_Is_Error (Context.Gate_Status) then
         Count := Count + 1;
      end if;
      return Count;
   end Count_Blockers;

   function Classify (Context : Replay_Context_Info) return Replay_Status is
      Blockers : constant Natural := Count_Blockers (Context);
   begin
      if Blockers > 1 then
         return Replay_Multiple_Blockers;
      elsif Blockers = 1 then
         if not Context.Source_Mapping_Present then
            return Replay_Source_Instance_Mapping_Missing;
         elsif not Context.Formal_Actual_Mapping_Present then
            return Replay_Formal_Actual_Mapping_Missing;
         elsif not Context.Diagnostic_Backmap_Present then
            return Replay_Diagnostic_Backmap_Missing;
         elsif Gate_Is_Error (Context.Gate_Status) then
            return Replay_Coverage_Gate_Blocker;
         elsif Expansion_Is_Error (Context.Expansion_Status) then
            return Replay_Generic_Expansion_Error;
         elsif Overload_Is_Error (Context.Overload_Status) then
            return Replay_Overload_Preference_Error;
         elsif Flow_Is_Error (Context.Flow_Status) then
            return Replay_Flow_Effect_Error;
         elsif Predicate_Is_Error (Context.Predicate_Status) then
            return Replay_Predicate_Propagation_Error;
         elsif Accessibility_Is_Error (Context.Accessibility_Status) then
            return Replay_Accessibility_Precision_Error;
         elsif Representation_Is_Error (Context.Representation_Status) then
            return Replay_Representation_Freezing_Error;
         end if;
      end if;

      if Context.Representation_Status /= Representation_Freezing.Representation_Freezing_Precision_Not_Checked then
         return Replay_Legal_Representation_Freezing;
      elsif Context.Accessibility_Status /= Access_Precision.Accessibility_Precision_Not_Checked then
         return Replay_Legal_Accessibility;
      elsif Context.Predicate_Status /= Predicate_Propagation.Propagation_Not_Checked then
         return Replay_Legal_Predicate_Invariant;
      elsif Context.Flow_Status /= Flow_Graph.Flow_Graph_Not_Checked then
         return Replay_Legal_Flow_Effect;
      elsif Context.Overload_Status /= Preference.Preference_Legality_Not_Checked then
         return Replay_Legal_Call;
      elsif Context.Expansion_Status /= Expansion.Generic_Body_Expansion_Not_Checked then
         case Context.Kind is
            when Replay_Context_Formal_Substitution |
                 Replay_Context_Body_Declaration =>
               return Replay_Legal_Substituted_Declaration;
            when Replay_Context_Body_Statement |
                 Replay_Context_Assignment |
                 Replay_Context_Return =>
               return Replay_Legal_Substituted_Statement;
            when Replay_Context_Generic_Nested_Instance =>
               return Replay_Legal_Nested_Instance;
            when others =>
               return Replay_Legal_Substituted_Expression;
         end case;
      else
         return Replay_Indeterminate;
      end if;
   end Classify;

   function Is_Legal (Status : Replay_Status) return Boolean is
   begin
      case Status is
         when Replay_Legal_Substituted_Declaration |
              Replay_Legal_Substituted_Statement |
              Replay_Legal_Substituted_Expression |
              Replay_Legal_Call |
              Replay_Legal_Flow_Effect |
              Replay_Legal_Predicate_Invariant |
              Replay_Legal_Accessibility |
              Replay_Legal_Representation_Freezing |
              Replay_Legal_Nested_Instance =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Legal;

   function Message_For (Status : Replay_Status) return String is
   begin
      case Status is
         when Replay_Legal_Substituted_Declaration =>
            return "generic instance body declaration replays legally after substitution";
         when Replay_Legal_Substituted_Statement =>
            return "generic instance body statement replays legally after substitution";
         when Replay_Legal_Substituted_Expression =>
            return "generic instance body expression replays legally after substitution";
         when Replay_Legal_Call =>
            return "generic instance body call resolves legally during semantic replay";
         when Replay_Legal_Flow_Effect =>
            return "generic instance body flow effect replays legally after substitution";
         when Replay_Legal_Predicate_Invariant =>
            return "generic instance body predicate/invariant obligation replays legally after substitution";
         when Replay_Legal_Accessibility =>
            return "generic instance body accessibility obligation replays legally after substitution";
         when Replay_Legal_Representation_Freezing =>
            return "generic instance body representation/freezing effect replays legally after substitution";
         when Replay_Legal_Nested_Instance =>
            return "nested generic instance body replay is legal after substitution";
         when Replay_Generic_Expansion_Error =>
            return "generic instance body replay is blocked by substitution expansion legality";
         when Replay_Overload_Preference_Error =>
            return "generic instance body replay is blocked by overload preference legality";
         when Replay_Flow_Effect_Error =>
            return "generic instance body replay is blocked by flow-effect legality";
         when Replay_Predicate_Propagation_Error =>
            return "generic instance body replay is blocked by predicate/invariant propagation legality";
         when Replay_Accessibility_Precision_Error =>
            return "generic instance body replay is blocked by accessibility precision legality";
         when Replay_Representation_Freezing_Error =>
            return "generic instance body replay is blocked by representation/freezing precision legality";
         when Replay_Coverage_Gate_Blocker =>
            return "generic instance body replay is blocked by coverage-gate enforcement";
         when Replay_Source_Instance_Mapping_Missing =>
            return "generic source to instance replay mapping is missing";
         when Replay_Formal_Actual_Mapping_Missing =>
            return "formal to actual replay mapping is missing";
         when Replay_Diagnostic_Backmap_Missing =>
            return "generic replay diagnostic backmap is missing";
         when Replay_Multiple_Blockers =>
            return "generic instance body replay has multiple semantic blockers";
         when others =>
            return "generic instance body semantic replay is indeterminate";
      end case;
   end Message_For;

   function Detail_For (Context : Replay_Context_Info) return String is
   begin
      return "generic=" & To_String (Context.Generic_Unit_Name)
        & "; instance=" & To_String (Context.Instance_Name)
        & "; formal=" & To_String (Context.Formal_Name)
        & "; actual=" & To_String (Context.Actual_Name)
        & "; blockers=" & Natural'Image (Count_Blockers (Context));
   end Detail_For;

   procedure Add_Row (Model : in out Replay_Model; Row : Replay_Info) is
   begin
      Model.Rows.Append (Row);
      if Is_Legal (Row.Status) then
         Model.Legal_Total := Model.Legal_Total + 1;
      else
         Model.Error_Total := Model.Error_Total + 1;
      end if;

      case Row.Status is
         when Replay_Source_Instance_Mapping_Missing |
              Replay_Formal_Actual_Mapping_Missing |
              Replay_Diagnostic_Backmap_Missing =>
            Model.Mapping_Error_Total := Model.Mapping_Error_Total + 1;
         when Replay_Generic_Expansion_Error =>
            Model.Expansion_Error_Total := Model.Expansion_Error_Total + 1;
         when Replay_Overload_Preference_Error =>
            Model.Overload_Error_Total := Model.Overload_Error_Total + 1;
         when Replay_Flow_Effect_Error =>
            Model.Flow_Error_Total := Model.Flow_Error_Total + 1;
         when Replay_Predicate_Propagation_Error =>
            Model.Predicate_Error_Total := Model.Predicate_Error_Total + 1;
         when Replay_Accessibility_Precision_Error =>
            Model.Accessibility_Error_Total := Model.Accessibility_Error_Total + 1;
         when Replay_Representation_Freezing_Error =>
            Model.Representation_Error_Total := Model.Representation_Error_Total + 1;
         when Replay_Coverage_Gate_Blocker =>
            Model.Coverage_Gate_Error_Total := Model.Coverage_Gate_Error_Total + 1;
         when Replay_Multiple_Blockers =>
            Model.Multiple_Blocker_Total := Model.Multiple_Blocker_Total + 1;
         when others =>
            null;
      end case;

      Model.Model_Fingerprint :=
        Mix (Model.Model_Fingerprint,
             Mix (Row.Fingerprint,
                  Mix (Natural (Row.Context), Status_Fingerprint (Row.Status))));
   end Add_Row;

   procedure Clear (Model : in out Replay_Context_Model) is
   begin
      Model.Entries.Clear;
      Model.Model_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Replay_Context_Model;
      Info  : Replay_Context_Info)
   is
      Item : Replay_Context_Info := Info;
   begin
      if Item.Id = No_Replay_Context then
         Item.Id := Replay_Context_Id (Natural (Model.Entries.Length) + 1);
      end if;
      Model.Entries.Append (Item);
      Model.Model_Fingerprint :=
        Mix (Model.Model_Fingerprint,
             Mix (Item.Source_Fingerprint,
                  Mix (Item.Substitution_Fingerprint,
                       Mix (Natural (Item.Node), Hash_Text (To_String (Item.Instance_Name))))));
   end Add_Context;

   procedure Add_From_Expansion_Row
     (Model : in out Replay_Context_Model;
      Row   : Expansion.Generic_Body_Expansion_Info)
   is
      Context : Replay_Context_Info;
   begin
      Context.Kind := Replay_Context_Formal_Substitution;
      Context.Node := Row.Node;
      Context.Generic_Source_Node := Row.Body_Node;
      Context.Instance_Node := Row.Instance_Node;
      Context.Formal_Node := Row.Formal_Node;
      Context.Body_Node := Row.Body_Node;
      Context.Formal_Name := Row.Formal_Name;
      Context.Actual_Name := Row.Actual_Text;
      Context.Expansion_Status := Row.Status;
      Context.Start_Line := Row.Start_Line;
      Context.Start_Column := Row.Start_Column;
      Context.End_Line := Row.End_Line;
      Context.End_Column := Row.End_Column;
      Context.Generic_Start_Line := Row.Start_Line;
      Context.Instance_Start_Line := Row.Start_Line;
      Context.Source_Fingerprint := Row.Fingerprint;
      Context.Substitution_Fingerprint := Row.Source_Fingerprint;
      Add_Context (Model, Context);
   end Add_From_Expansion_Row;

   function Context_Count (Model : Replay_Context_Model) return Natural is
   begin
      return Natural (Model.Entries.Length);
   end Context_Count;

   function Context_At
     (Model : Replay_Context_Model;
      Index : Positive) return Replay_Context_Info is
   begin
      if Index > Natural (Model.Entries.Length) then
         return (others => <>);
      end if;
      return Model.Entries.Element (Index);
   end Context_At;

   function Fingerprint (Model : Replay_Context_Model) return Natural is
   begin
      return Model.Model_Fingerprint;
   end Fingerprint;

   function Build (Contexts : Replay_Context_Model) return Replay_Model is
      Model : Replay_Model;
   begin
      for Context of Contexts.Entries loop
         declare
            Row : Replay_Info;
         begin
            Row.Id := Replay_Row_Id (Natural (Model.Rows.Length) + 1);
            Row.Context := Context.Id;
            Row.Kind := Context.Kind;
            Row.Status := Classify (Context);
            Row.Node := Context.Node;
            Row.Generic_Source_Node := Context.Generic_Source_Node;
            Row.Instance_Node := Context.Instance_Node;
            Row.Formal_Node := Context.Formal_Node;
            Row.Actual_Node := Context.Actual_Node;
            Row.Body_Node := Context.Body_Node;
            Row.Formal_Name := Context.Formal_Name;
            Row.Actual_Name := Context.Actual_Name;
            Row.Generic_Unit_Name := Context.Generic_Unit_Name;
            Row.Instance_Name := Context.Instance_Name;
            Row.Blocker_Count := Count_Blockers (Context);
            Row.Expansion_Status := Context.Expansion_Status;
            Row.Overload_Status := Context.Overload_Status;
            Row.Flow_Status := Context.Flow_Status;
            Row.Predicate_Status := Context.Predicate_Status;
            Row.Accessibility_Status := Context.Accessibility_Status;
            Row.Representation_Status := Context.Representation_Status;
            Row.Gate_Status := Context.Gate_Status;
            Row.Start_Line := Context.Start_Line;
            Row.Start_Column := Context.Start_Column;
            Row.End_Line := Context.End_Line;
            Row.End_Column := Context.End_Column;
            Row.Generic_Start_Line := Context.Generic_Start_Line;
            Row.Generic_Start_Column := Context.Generic_Start_Column;
            Row.Instance_Start_Line := Context.Instance_Start_Line;
            Row.Instance_Start_Column := Context.Instance_Start_Column;
            Row.Source_Fingerprint := Context.Source_Fingerprint;
            Row.Substitution_Fingerprint := Context.Substitution_Fingerprint;
            Row.Message := To_Unbounded_String (Message_For (Row.Status));
            Row.Detail := To_Unbounded_String (Detail_For (Context));
            Row.Fingerprint :=
              Mix (Context.Source_Fingerprint,
                   Mix (Context.Substitution_Fingerprint,
                        Mix (Status_Fingerprint (Row.Status),
                             Mix (Hash_Text (To_String (Context.Formal_Name)),
                                  Hash_Text (To_String (Context.Actual_Name))))));
            Add_Row (Model, Row);
         end;
      end loop;
      Model.Model_Fingerprint := Mix (Model.Model_Fingerprint, Fingerprint (Contexts));
      return Model;
   end Build;

   function Build_From_Expansion
     (Expansion_Model : Expansion.Generic_Body_Expansion_Model) return Replay_Model
   is
      Contexts : Replay_Context_Model;
   begin
      for Index in 1 .. Expansion.Row_Count (Expansion_Model) loop
         Add_From_Expansion_Row (Contexts, Expansion.Row_At (Expansion_Model, Index));
      end loop;
      return Build (Contexts);
   end Build_From_Expansion;

   function Row_Count (Model : Replay_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At (Model : Replay_Model; Index : Positive) return Replay_Info is
   begin
      if Index > Natural (Model.Rows.Length) then
         return (others => <>);
      end if;
      return Model.Rows.Element (Index);
   end Row_At;

   function First_For_Node
     (Model : Replay_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Replay_Info is
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Replay_Model;
      Status : Replay_Status) return Replay_Result_Set
   is
      Results : Replay_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Results.Entries.Append (Row);
         end if;
      end loop;
      return Results;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Replay_Model;
      Kind  : Replay_Context_Kind) return Replay_Result_Set
   is
      Results : Replay_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Results.Entries.Append (Row);
         end if;
      end loop;
      return Results;
   end Rows_For_Kind;

   function Rows_For_Instance
     (Model : Replay_Model;
      Name  : String) return Replay_Result_Set
   is
      Results    : Replay_Result_Set;
      Normalized : constant String := Ada.Characters.Handling.To_Lower (Name);
   begin
      for Row of Model.Rows loop
         if Normalize (Row.Instance_Name) = Normalized then
            Results.Entries.Append (Row);
         end if;
      end loop;
      return Results;
   end Rows_For_Instance;

   function Result_Count (Results : Replay_Result_Set) return Natural is
   begin
      return Natural (Results.Entries.Length);
   end Result_Count;

   function Result_At
     (Results : Replay_Result_Set;
      Index   : Positive) return Replay_Info is
   begin
      if Index > Natural (Results.Entries.Length) then
         return (others => <>);
      end if;
      return Results.Entries.Element (Index);
   end Result_At;

   function Count_Status
     (Model  : Replay_Model;
      Status : Replay_Status) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Legal_Count (Model : Replay_Model) return Natural is
   begin
      return Model.Legal_Total;
   end Legal_Count;

   function Error_Count (Model : Replay_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Mapping_Error_Count (Model : Replay_Model) return Natural is
   begin
      return Model.Mapping_Error_Total;
   end Mapping_Error_Count;

   function Expansion_Error_Count (Model : Replay_Model) return Natural is
   begin
      return Model.Expansion_Error_Total;
   end Expansion_Error_Count;

   function Overload_Error_Count (Model : Replay_Model) return Natural is
   begin
      return Model.Overload_Error_Total;
   end Overload_Error_Count;

   function Flow_Error_Count (Model : Replay_Model) return Natural is
   begin
      return Model.Flow_Error_Total;
   end Flow_Error_Count;

   function Predicate_Error_Count (Model : Replay_Model) return Natural is
   begin
      return Model.Predicate_Error_Total;
   end Predicate_Error_Count;

   function Accessibility_Error_Count (Model : Replay_Model) return Natural is
   begin
      return Model.Accessibility_Error_Total;
   end Accessibility_Error_Count;

   function Representation_Error_Count (Model : Replay_Model) return Natural is
   begin
      return Model.Representation_Error_Total;
   end Representation_Error_Count;

   function Coverage_Gate_Error_Count (Model : Replay_Model) return Natural is
   begin
      return Model.Coverage_Gate_Error_Total;
   end Coverage_Gate_Error_Count;

   function Multiple_Blocker_Count (Model : Replay_Model) return Natural is
   begin
      return Model.Multiple_Blocker_Total;
   end Multiple_Blocker_Count;

   function Fingerprint (Model : Replay_Model) return Natural is
   begin
      return Model.Model_Fingerprint;
   end Fingerprint;

end Editor.Ada_Generic_Instance_Body_Semantic_Replay;
