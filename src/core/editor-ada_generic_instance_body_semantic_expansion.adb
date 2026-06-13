with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Generic_Instance_Body_Semantic_Expansion is

   package GA renames Editor.Ada_Generic_Instantiated_Body_Analysis;
   package OA renames Editor.Ada_Overload_Resolution_Legality;
   package AA renames Editor.Ada_Accessibility_Lifetime_Legality;
   package CA renames Editor.Ada_Contract_Aspect_Legality;
   package DA renames Editor.Ada_Dataflow_Global_Depends_Legality;
   package IA renames Editor.Ada_Definite_Initialization_Flow_Legality;
   package PA renames Editor.Ada_Predicate_Invariant_Use_Site_Legality;
   package RA renames Editor.Ada_Representation_Layout_Stream_Integration_Legality;

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type GA.Instantiated_Body_Substitution_Id;
   use type GA.Instantiated_Body_Status;
   use type OA.Overload_Legality_Status;
   use type AA.Accessibility_Legality_Status;
   use type CA.Contract_Legality_Status;
   use type DA.Dataflow_Legality_Status;
   use type IA.Initialization_Legality_Status;
   use type PA.Predicate_Use_Legality_Status;
   use type RA.Representation_Integration_Status;


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

   function Status_Fingerprint (Status : Generic_Body_Expansion_Status) return Natural is
   begin
      return Generic_Body_Expansion_Status'Pos (Status) * 1_000_003;
   end Status_Fingerprint;

   function Normalize (Text : Unbounded_String) return String is
   begin
      return Ada.Characters.Handling.To_Lower (To_String (Text));
   end Normalize;

   function Body_Is_Legal (Status : Instantiated_Body_Status) return Boolean is
   begin
      return Status = GA.Instantiated_Body_Substituted
        or else Status = GA.Instantiated_Body_Default_Substituted;
   end Body_Is_Legal;

   function Overload_Is_Error (Status : Overload_Legality_Status) return Boolean is
   begin
      case Status is
         when OA.Overload_Legality_Not_Checked |
              OA.Overload_Legality_Legal_Exact |
              OA.Overload_Legality_Legal_Expected_Type_Preferred |
              OA.Overload_Legality_Legal_Universal_Integer_Preferred |
              OA.Overload_Legality_Legal_Universal_Real_Preferred |
              OA.Overload_Legality_Legal_Primitive_Operator_Preferred |
              OA.Overload_Legality_Legal_Implicit_Numeric_Conversion |
              OA.Overload_Legality_Legal_Class_Wide_Conversion |
              OA.Overload_Legality_Legal_Access_Conversion |
              OA.Overload_Legality_Legal_Named_Actual_Profile |
              OA.Overload_Legality_Legal_Defaulted_Formal_Profile =>
            return False;
         when others =>
            return True;
      end case;
   end Overload_Is_Error;

   function Accessibility_Is_Error (Status : Accessibility_Legality_Status) return Boolean is
   begin
      case Status is
         when AA.Accessibility_Legality_Not_Checked |
              AA.Accessibility_Legality_Static_Compatible |
              AA.Accessibility_Legality_Dynamic_Check_Required |
              AA.Accessibility_Legality_Null_Exclusion_Checked |
              AA.Accessibility_Legality_Aliased_Object_Compatible |
              AA.Accessibility_Legality_Allocator_Compatible |
              AA.Accessibility_Legality_Access_Conversion_Compatible |
              AA.Accessibility_Legality_Return_Access_Compatible =>
            return False;
         when others =>
            return True;
      end case;
   end Accessibility_Is_Error;

   function Contract_Is_Error (Status : Contract_Legality_Status) return Boolean is
   begin
      case Status is
         when CA.Contract_Legality_Not_Checked |
              CA.Contract_Legality_Legal_Precondition |
              CA.Contract_Legality_Legal_Postcondition |
              CA.Contract_Legality_Legal_Invariant |
              CA.Contract_Legality_Legal_Predicate |
              CA.Contract_Legality_Legal_Assertion |
              CA.Contract_Legality_Legal_Contract_Case |
              CA.Contract_Legality_Legal_Flow_Aspect =>
            return False;
         when others =>
            return True;
      end case;
   end Contract_Is_Error;

   function Dataflow_Is_Error (Status : Dataflow_Legality_Status) return Boolean is
   begin
      case Status is
         when DA.Dataflow_Legality_Not_Checked |
              DA.Dataflow_Legality_Legal_Read |
              DA.Dataflow_Legality_Legal_Write |
              DA.Dataflow_Legality_Legal_Read_Write |
              DA.Dataflow_Legality_Legal_Null_Effect |
              DA.Dataflow_Legality_Legal_Depends_Edge |
              DA.Dataflow_Legality_Legal_Refinement =>
            return False;
         when others =>
            return True;
      end case;
   end Dataflow_Is_Error;

   function Initialization_Is_Error (Status : Initialization_Legality_Status) return Boolean is
   begin
      case Status is
         when IA.Initialization_Legality_Not_Checked |
              IA.Initialization_Legality_Definitely_Initialized |
              IA.Initialization_Legality_Default_Initialized |
              IA.Initialization_Legality_Explicitly_Initialized |
              IA.Initialization_Legality_Component_Initialized |
              IA.Initialization_Legality_Out_Parameter_Assigned |
              IA.Initialization_Legality_Return_Object_Initialized |
              IA.Initialization_Legality_Exception_Path_Preserved |
              IA.Initialization_Legality_Finalization_Path_Preserved |
              IA.Initialization_Legality_Unreachable_Initialization =>
            return False;
         when others =>
            return True;
      end case;
   end Initialization_Is_Error;

   function Predicate_Is_Error (Status : Predicate_Use_Legality_Status) return Boolean is
   begin
      case Status is
         when PA.Predicate_Use_Legality_Not_Checked |
              PA.Predicate_Use_Legality_Legal_Static_Predicate |
              PA.Predicate_Use_Legality_Legal_Dynamic_Predicate_Check |
              PA.Predicate_Use_Legality_Legal_Invariant_Preserved |
              PA.Predicate_Use_Legality_Legal_Dynamic_Invariant_Check |
              PA.Predicate_Use_Legality_Legal_Static_Range_And_Predicate |
              PA.Predicate_Use_Legality_Legal_Linked_Assignment |
              PA.Predicate_Use_Legality_Legal_Linked_Return |
              PA.Predicate_Use_Legality_Legal_Linked_Semantic |
              PA.Predicate_Use_Legality_Legal_Linked_Overload |
              PA.Predicate_Use_Legality_Legal_Linked_Generic_Actual =>
            return False;
         when others =>
            return True;
      end case;
   end Predicate_Is_Error;

   function Representation_Is_Error (Status : Representation_Integration_Status) return Boolean is
   begin
      case Status is
         when RA.Representation_Integration_Not_Checked |
              RA.Representation_Integration_Legal_Representation_Item |
              RA.Representation_Integration_Legal_Record_Layout |
              RA.Representation_Integration_Legal_Stream_Attribute |
              RA.Representation_Integration_Legal_Operational_Attribute |
              RA.Representation_Integration_Legal_Convention |
              RA.Representation_Integration_Legal_Generic_Instance_Effect |
              RA.Representation_Integration_Legal_Finalization_Effect =>
            return False;
         when others =>
            return True;
      end case;
   end Representation_Is_Error;

   function Count_Blockers (Context : Generic_Body_Expansion_Context_Info) return Natural is
      Count : Natural := 0;
   begin
      if not Body_Is_Legal (Context.Body_Status)
        and then Context.Body_Status /= GA.Instantiated_Body_Not_Checked
      then
         Count := Count + 1;
      end if;
      if Overload_Is_Error (Context.Overload_Status) then
         Count := Count + 1;
      end if;
      if Accessibility_Is_Error (Context.Accessibility_Status) then
         Count := Count + 1;
      end if;
      if Contract_Is_Error (Context.Contract_Status) then
         Count := Count + 1;
      end if;
      if Dataflow_Is_Error (Context.Dataflow_Status) then
         Count := Count + 1;
      end if;
      if Initialization_Is_Error (Context.Initialization_Status) then
         Count := Count + 1;
      end if;
      if Predicate_Is_Error (Context.Predicate_Status) then
         Count := Count + 1;
      end if;
      if Representation_Is_Error (Context.Representation_Status) then
         Count := Count + 1;
      end if;
      return Count;
   end Count_Blockers;

   function Classify_Body_Status
     (Status : Instantiated_Body_Status) return Generic_Body_Expansion_Status is
   begin
      case Status is
         when GA.Instantiated_Body_Substituted =>
            return Generic_Body_Expansion_Legal_Substitution;
         when GA.Instantiated_Body_Default_Substituted =>
            return Generic_Body_Expansion_Legal_Default_Substitution;
         when GA.Instantiated_Body_Private_View_Barrier =>
            return Generic_Body_Expansion_Private_View_Barrier;
         when GA.Instantiated_Body_Limited_View_Barrier =>
            return Generic_Body_Expansion_Limited_View_Barrier;
         when GA.Instantiated_Body_Cross_Unit_Unresolved =>
            return Generic_Body_Expansion_Cross_Unit_Unresolved;
         when GA.Instantiated_Body_Object_Mismatch =>
            return Generic_Body_Expansion_Object_Mismatch;
         when GA.Instantiated_Body_Object_Unknown =>
            return Generic_Body_Expansion_Object_Unknown;
         when GA.Instantiated_Body_No_Body_Contract =>
            return Generic_Body_Expansion_Missing_Body_Contract;
         when GA.Instantiated_Body_Contract_Mismatch =>
            return Generic_Body_Expansion_Contract_Mismatch;
         when others =>
            return Generic_Body_Expansion_Indeterminate;
      end case;
   end Classify_Body_Status;

   function Classify (Context : Generic_Body_Expansion_Context_Info)
      return Generic_Body_Expansion_Status
   is
      Blockers : constant Natural := Count_Blockers (Context);
   begin
      if Blockers > 1 then
         return Generic_Body_Expansion_Multiple_Semantic_Blockers;
      elsif Blockers = 0 then
         if Context.Representation_Status /= RA.Representation_Integration_Not_Checked then
            return Generic_Body_Expansion_Legal_Representation;
         elsif Context.Predicate_Status /= PA.Predicate_Use_Legality_Not_Checked then
            return Generic_Body_Expansion_Legal_Predicate_Invariant;
         elsif Context.Initialization_Status /= IA.Initialization_Legality_Not_Checked then
            return Generic_Body_Expansion_Legal_Initialization;
         elsif Context.Dataflow_Status /= DA.Dataflow_Legality_Not_Checked then
            return Generic_Body_Expansion_Legal_Dataflow;
         elsif Context.Contract_Status /= CA.Contract_Legality_Not_Checked then
            return Generic_Body_Expansion_Legal_Contract;
         elsif Context.Accessibility_Status /= AA.Accessibility_Legality_Not_Checked then
            return Generic_Body_Expansion_Legal_Accessibility;
         elsif Context.Overload_Status /= OA.Overload_Legality_Not_Checked then
            return Generic_Body_Expansion_Legal_Overload;
         elsif Context.Body_Status = GA.Instantiated_Body_Default_Substituted then
            return Generic_Body_Expansion_Legal_Default_Substitution;
         elsif Context.Body_Status = GA.Instantiated_Body_Substituted then
            return Generic_Body_Expansion_Legal_Substitution;
         else
            return Generic_Body_Expansion_Indeterminate;
         end if;
      end if;

      if Overload_Is_Error (Context.Overload_Status) then
         return Generic_Body_Expansion_Overload_Error;
      elsif Accessibility_Is_Error (Context.Accessibility_Status) then
         return Generic_Body_Expansion_Accessibility_Error;
      elsif Contract_Is_Error (Context.Contract_Status) then
         return Generic_Body_Expansion_Contract_Error;
      elsif Dataflow_Is_Error (Context.Dataflow_Status) then
         return Generic_Body_Expansion_Dataflow_Error;
      elsif Initialization_Is_Error (Context.Initialization_Status) then
         return Generic_Body_Expansion_Initialization_Error;
      elsif Predicate_Is_Error (Context.Predicate_Status) then
         return Generic_Body_Expansion_Predicate_Invariant_Error;
      elsif Representation_Is_Error (Context.Representation_Status) then
         return Generic_Body_Expansion_Representation_Error;
      else
         return Classify_Body_Status (Context.Body_Status);
      end if;
   end Classify;

   function Is_Legal (Status : Generic_Body_Expansion_Status) return Boolean is
   begin
      case Status is
         when Generic_Body_Expansion_Legal_Substitution |
              Generic_Body_Expansion_Legal_Default_Substitution |
              Generic_Body_Expansion_Legal_Overload |
              Generic_Body_Expansion_Legal_Accessibility |
              Generic_Body_Expansion_Legal_Contract |
              Generic_Body_Expansion_Legal_Dataflow |
              Generic_Body_Expansion_Legal_Initialization |
              Generic_Body_Expansion_Legal_Predicate_Invariant |
              Generic_Body_Expansion_Legal_Representation =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Legal;

   function Message_For (Status : Generic_Body_Expansion_Status) return String is
   begin
      case Status is
         when Generic_Body_Expansion_Legal_Substitution =>
            return "generic body formal is substituted by a legal actual";
         when Generic_Body_Expansion_Legal_Default_Substitution =>
            return "generic body formal uses a legal default actual substitution";
         when Generic_Body_Expansion_Legal_Overload =>
            return "generic instance body overload use is legal after substitution";
         when Generic_Body_Expansion_Legal_Accessibility =>
            return "generic instance body accessibility use is legal after substitution";
         when Generic_Body_Expansion_Legal_Contract =>
            return "generic instance body contract use is legal after substitution";
         when Generic_Body_Expansion_Legal_Dataflow =>
            return "generic instance body dataflow use is legal after substitution";
         when Generic_Body_Expansion_Legal_Initialization =>
            return "generic instance body initialization use is legal after substitution";
         when Generic_Body_Expansion_Legal_Predicate_Invariant =>
            return "generic instance body predicate/invariant use is legal after substitution";
         when Generic_Body_Expansion_Legal_Representation =>
            return "generic instance body representation effect is legal after substitution";
         when Generic_Body_Expansion_Private_View_Barrier =>
            return "generic instance body substitution is blocked by a private-view barrier";
         when Generic_Body_Expansion_Limited_View_Barrier =>
            return "generic instance body substitution is blocked by a limited-view barrier";
         when Generic_Body_Expansion_Cross_Unit_Unresolved =>
            return "generic instance body substitution depends on unresolved cross-unit metadata";
         when Generic_Body_Expansion_Object_Mismatch =>
            return "generic instance body actual does not match the formal object";
         when Generic_Body_Expansion_Object_Unknown =>
            return "generic instance body actual object is unknown";
         when Generic_Body_Expansion_Missing_Body_Contract =>
            return "generic instance body contract is missing";
         when Generic_Body_Expansion_Contract_Mismatch =>
            return "generic instance body contract does not match the actual substitution";
         when Generic_Body_Expansion_Overload_Error =>
            return "generic instance body overload legality failed after substitution";
         when Generic_Body_Expansion_Accessibility_Error =>
            return "generic instance body accessibility legality failed after substitution";
         when Generic_Body_Expansion_Contract_Error =>
            return "generic instance body contract/aspect legality failed after substitution";
         when Generic_Body_Expansion_Dataflow_Error =>
            return "generic instance body Global/Depends dataflow legality failed after substitution";
         when Generic_Body_Expansion_Initialization_Error =>
            return "generic instance body definite-initialization legality failed after substitution";
         when Generic_Body_Expansion_Predicate_Invariant_Error =>
            return "generic instance body predicate/invariant legality failed after substitution";
         when Generic_Body_Expansion_Representation_Error =>
            return "generic instance body representation legality failed after substitution";
         when Generic_Body_Expansion_Multiple_Semantic_Blockers =>
            return "generic instance body expansion has multiple semantic blockers";
         when others =>
            return "generic instance body semantic expansion is indeterminate";
      end case;
   end Message_For;

   function Detail_For (Context : Generic_Body_Expansion_Context_Info) return String is
   begin
      return "formal=" & To_String (Context.Formal_Name)
        & "; actual=" & To_String (Context.Actual_Text)
        & "; blockers=" & Natural'Image (Count_Blockers (Context));
   end Detail_For;

   procedure Add_Row
     (Model : in out Generic_Body_Expansion_Model;
      Row   : Generic_Body_Expansion_Info) is
   begin
      Model.Rows.Append (Row);
      if Is_Legal (Row.Status) then
         Model.Legal_Total := Model.Legal_Total + 1;
      else
         Model.Error_Total := Model.Error_Total + 1;
      end if;

      case Row.Status is
         when Generic_Body_Expansion_Private_View_Barrier |
              Generic_Body_Expansion_Limited_View_Barrier |
              Generic_Body_Expansion_Cross_Unit_Unresolved =>
            Model.View_Barrier_Total := Model.View_Barrier_Total + 1;
         when Generic_Body_Expansion_Overload_Error =>
            Model.Overload_Error_Total := Model.Overload_Error_Total + 1;
         when Generic_Body_Expansion_Accessibility_Error =>
            Model.Accessibility_Error_Total := Model.Accessibility_Error_Total + 1;
         when Generic_Body_Expansion_Contract_Error |
              Generic_Body_Expansion_Contract_Mismatch |
              Generic_Body_Expansion_Missing_Body_Contract =>
            Model.Contract_Error_Total := Model.Contract_Error_Total + 1;
         when Generic_Body_Expansion_Dataflow_Error =>
            Model.Dataflow_Error_Total := Model.Dataflow_Error_Total + 1;
         when Generic_Body_Expansion_Initialization_Error =>
            Model.Initialization_Error_Total := Model.Initialization_Error_Total + 1;
         when Generic_Body_Expansion_Predicate_Invariant_Error =>
            Model.Predicate_Error_Total := Model.Predicate_Error_Total + 1;
         when Generic_Body_Expansion_Representation_Error =>
            Model.Representation_Error_Total := Model.Representation_Error_Total + 1;
         when Generic_Body_Expansion_Multiple_Semantic_Blockers =>
            Model.Multiple_Blocker_Total := Model.Multiple_Blocker_Total + 1;
         when others =>
            null;
      end case;

      Model.Model_Fingerprint :=
        Mix (Model.Model_Fingerprint,
             Mix (Row.Fingerprint,
                  Mix (Natural (Row.Context),
                       Mix (Natural (Row.Substitution), Status_Fingerprint (Row.Status)))));
   end Add_Row;

   procedure Add_Context
     (Model : in out Generic_Body_Expansion_Context_Model;
      Info  : Generic_Body_Expansion_Context_Info)
   is
      Item : Generic_Body_Expansion_Context_Info := Info;
   begin
      if Item.Id = No_Generic_Body_Expansion_Context then
         Item.Id := Generic_Body_Expansion_Context_Id (Natural (Model.Entries.Length) + 1);
      end if;
      Model.Entries.Append (Item);
      Model.Model_Fingerprint :=
        Mix (Model.Model_Fingerprint,
             Mix (Item.Source_Fingerprint,
                  Mix (Natural (Item.Id),
                       Mix (Natural (Item.Node), Hash_Text (To_String (Item.Formal_Name))))));
   end Add_Context;

   procedure Clear (Model : in out Generic_Body_Expansion_Context_Model) is
   begin
      Model.Entries.Clear;
      Model.Model_Fingerprint := 0;
   end Clear;

   function Context_Count (Model : Generic_Body_Expansion_Context_Model) return Natural is
   begin
      return Natural (Model.Entries.Length);
   end Context_Count;

   function Context_At
     (Model : Generic_Body_Expansion_Context_Model;
      Index : Positive) return Generic_Body_Expansion_Context_Info is
   begin
      if Index > Natural (Model.Entries.Length) then
         return (others => <>);
      end if;
      return Model.Entries.Element (Index);
   end Context_At;

   function Fingerprint (Model : Generic_Body_Expansion_Context_Model) return Natural is
   begin
      return Model.Model_Fingerprint;
   end Fingerprint;

   function Build
     (Contexts : Generic_Body_Expansion_Context_Model) return Generic_Body_Expansion_Model
   is
      Model : Generic_Body_Expansion_Model;
   begin
      for Context of Contexts.Entries loop
         declare
            Row : Generic_Body_Expansion_Info;
         begin
            Row.Id := Generic_Body_Expansion_Id (Natural (Model.Rows.Length) + 1);
            Row.Context := Context.Id;
            Row.Kind := Context.Kind;
            Row.Status := Classify (Context);
            Row.Node := Context.Node;
            Row.Instance_Node := Context.Instance_Node;
            Row.Formal_Node := Context.Formal_Node;
            Row.Body_Node := Context.Body_Node;
            Row.Substitution := Context.Substitution;
            Row.Formal_Name := Context.Formal_Name;
            Row.Actual_Text := Context.Actual_Text;
            Row.Body_Status := Context.Body_Status;
            Row.Overload_Status := Context.Overload_Status;
            Row.Accessibility_Status := Context.Accessibility_Status;
            Row.Contract_Status := Context.Contract_Status;
            Row.Dataflow_Status := Context.Dataflow_Status;
            Row.Initialization_Status := Context.Initialization_Status;
            Row.Predicate_Status := Context.Predicate_Status;
            Row.Representation_Status := Context.Representation_Status;
            Row.Blocker_Count := Count_Blockers (Context);
            Row.Message := To_Unbounded_String (Message_For (Row.Status));
            Row.Detail := To_Unbounded_String (Detail_For (Context));
            Row.Start_Line := Context.Start_Line;
            Row.Start_Column := Context.Start_Column;
            Row.End_Line := Context.End_Line;
            Row.End_Column := Context.End_Column;
            Row.Source_Fingerprint := Context.Source_Fingerprint;
            Row.Fingerprint :=
              Mix (Context.Source_Fingerprint,
                   Mix (Status_Fingerprint (Row.Status),
                        Mix (Hash_Text (To_String (Context.Formal_Name)),
                             Mix (Hash_Text (To_String (Context.Actual_Text)), Row.Blocker_Count))));
            Add_Row (Model, Row);
         end;
      end loop;
      Model.Model_Fingerprint := Mix (Model.Model_Fingerprint, Fingerprint (Contexts));
      return Model;
   end Build;

   function Build_From_Instantiated_Bodies
     (Bodies : Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Model)
      return Generic_Body_Expansion_Model
   is
      Contexts : Generic_Body_Expansion_Context_Model;
   begin
      for Index in 1 .. GA.Substitution_Count (Bodies) loop
         declare
            Body_Info : constant GA.Instantiated_Body_Substitution_Info :=
              GA.Substitution_At (Bodies, Index);
            Context : Generic_Body_Expansion_Context_Info;
         begin
            Context.Id := Generic_Body_Expansion_Context_Id (Index);
            Context.Kind := Generic_Body_Expansion_Formal_Object;
            Context.Node := Body_Info.Instance_Node;
            Context.Instance_Node := Body_Info.Instance_Node;
            Context.Formal_Node := Body_Info.Formal_Node;
            Context.Body_Node := Body_Info.Body_Node;
            Context.Substitution := Body_Info.Id;
            Context.Formal_Name := Body_Info.Formal_Name;
            Context.Formal_Subtype := Body_Info.Formal_Subtype;
            Context.Actual_Text := Body_Info.Actual_Text;
            Context.Is_Default_Substitution := Body_Info.Is_Default;
            Context.Body_Status := Body_Info.Status;
            Context.Start_Line := Body_Info.Start_Line;
            Context.End_Line := Body_Info.End_Line;
            Context.Source_Fingerprint := Body_Info.Fingerprint;
            Add_Context (Contexts, Context);
         end;
      end loop;
      return Build (Contexts);
   end Build_From_Instantiated_Bodies;

   function Row_Count (Model : Generic_Body_Expansion_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : Generic_Body_Expansion_Model;
      Index : Positive) return Generic_Body_Expansion_Info is
   begin
      if Index > Natural (Model.Rows.Length) then
         return (others => <>);
      end if;
      return Model.Rows.Element (Index);
   end Row_At;

   function First_For_Context
     (Model   : Generic_Body_Expansion_Model;
      Context : Generic_Body_Expansion_Context_Id) return Generic_Body_Expansion_Info is
   begin
      for Row of Model.Rows loop
         if Row.Context = Context then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Context;

   function First_For_Substitution
     (Model        : Generic_Body_Expansion_Model;
      Substitution : GA.Instantiated_Body_Substitution_Id)
      return Generic_Body_Expansion_Info is
   begin
      for Row of Model.Rows loop
         if Row.Substitution = Substitution then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Substitution;

   function Rows_For_Status
     (Model  : Generic_Body_Expansion_Model;
      Status : Generic_Body_Expansion_Status) return Generic_Body_Expansion_Result_Set
   is
      Results : Generic_Body_Expansion_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Results.Entries.Append (Row);
         end if;
      end loop;
      return Results;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Generic_Body_Expansion_Model;
      Kind  : Generic_Body_Expansion_Context_Kind) return Generic_Body_Expansion_Result_Set
   is
      Results : Generic_Body_Expansion_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Results.Entries.Append (Row);
         end if;
      end loop;
      return Results;
   end Rows_For_Kind;

   function Rows_For_Formal
     (Model       : Generic_Body_Expansion_Model;
      Formal_Name : String) return Generic_Body_Expansion_Result_Set
   is
      Results    : Generic_Body_Expansion_Result_Set;
      Normalized : constant String := Ada.Characters.Handling.To_Lower (Formal_Name);
   begin
      for Row of Model.Rows loop
         if Normalize (Row.Formal_Name) = Normalized then
            Results.Entries.Append (Row);
         end if;
      end loop;
      return Results;
   end Rows_For_Formal;

   function Result_Count (Results : Generic_Body_Expansion_Result_Set) return Natural is
   begin
      return Natural (Results.Entries.Length);
   end Result_Count;

   function Result_At
     (Results : Generic_Body_Expansion_Result_Set;
      Index   : Positive) return Generic_Body_Expansion_Info is
   begin
      if Index > Natural (Results.Entries.Length) then
         return (others => <>);
      end if;
      return Results.Entries.Element (Index);
   end Result_At;

   function Count_Status
     (Model  : Generic_Body_Expansion_Model;
      Status : Generic_Body_Expansion_Status) return Natural
   is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Legal_Count (Model : Generic_Body_Expansion_Model) return Natural is
   begin
      return Model.Legal_Total;
   end Legal_Count;

   function Error_Count (Model : Generic_Body_Expansion_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function View_Barrier_Count (Model : Generic_Body_Expansion_Model) return Natural is
   begin
      return Model.View_Barrier_Total;
   end View_Barrier_Count;

   function Overload_Error_Count (Model : Generic_Body_Expansion_Model) return Natural is
   begin
      return Model.Overload_Error_Total;
   end Overload_Error_Count;

   function Accessibility_Error_Count (Model : Generic_Body_Expansion_Model) return Natural is
   begin
      return Model.Accessibility_Error_Total;
   end Accessibility_Error_Count;

   function Contract_Error_Count (Model : Generic_Body_Expansion_Model) return Natural is
   begin
      return Model.Contract_Error_Total;
   end Contract_Error_Count;

   function Dataflow_Error_Count (Model : Generic_Body_Expansion_Model) return Natural is
   begin
      return Model.Dataflow_Error_Total;
   end Dataflow_Error_Count;

   function Initialization_Error_Count (Model : Generic_Body_Expansion_Model) return Natural is
   begin
      return Model.Initialization_Error_Total;
   end Initialization_Error_Count;

   function Predicate_Error_Count (Model : Generic_Body_Expansion_Model) return Natural is
   begin
      return Model.Predicate_Error_Total;
   end Predicate_Error_Count;

   function Representation_Error_Count (Model : Generic_Body_Expansion_Model) return Natural is
   begin
      return Model.Representation_Error_Total;
   end Representation_Error_Count;

   function Multiple_Blocker_Count (Model : Generic_Body_Expansion_Model) return Natural is
   begin
      return Model.Multiple_Blocker_Total;
   end Multiple_Blocker_Count;

   function Fingerprint (Model : Generic_Body_Expansion_Model) return Natural is
   begin
      return Model.Model_Fingerprint;
   end Fingerprint;

end Editor.Ada_Generic_Instance_Body_Semantic_Expansion;
