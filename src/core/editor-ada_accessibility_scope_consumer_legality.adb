with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Accessibility_Scope_Consumer_Legality is


   use type Scope.Scope_Legality_Id;
   use type Disc_Gen.Discriminant_Generic_Row_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 131) + B + 17) mod 2_147_483_647;
   end Mix;

   function S (Value : Ada.Strings.Unbounded.Unbounded_String) return String is
   begin
      return To_String (Value);
   end S;

   function Text_Fingerprint (Value : Ada.Strings.Unbounded.Unbounded_String) return Natural is
      R : Natural := 0;
   begin
      for Ch of S (Value) loop
         R := Mix (R, Character'Pos (Ch));
      end loop;
      return R;
   end Text_Fingerprint;

   function Is_Legal_Scope (Status : Scope.Scope_Legality_Status) return Boolean is
   begin
      return Status in Scope.Scope_Legality_Legal_Master_Hierarchy |
                       Scope.Scope_Legality_Legal_Static_Level |
                       Scope.Scope_Legality_Legal_Dynamic_Check |
                       Scope.Scope_Legality_Legal_Allocator_Master |
                       Scope.Scope_Legality_Legal_Return_Object_Master |
                       Scope.Scope_Legality_Legal_Return_Access_Master |
                       Scope.Scope_Legality_Legal_Access_Discriminant_Master |
                       Scope.Scope_Legality_Legal_Access_Conversion |
                       Scope.Scope_Legality_Legal_Generic_Substitution |
                       Scope.Scope_Legality_Legal_Discriminant_Aggregate;
   end Is_Legal_Scope;

   function Needs_Discriminant_Generic
     (Kind : Accessibility_Consumer_Context_Kind) return Boolean is
   begin
      return Kind in Accessibility_Consumer_Access_Discriminant |
                     Accessibility_Consumer_Generic_Replay |
                     Accessibility_Consumer_Generic_Actual |
                     Accessibility_Consumer_Record_Aggregate |
                     Accessibility_Consumer_Representation_Clause |
                     Accessibility_Consumer_Record_Layout |
                     Accessibility_Consumer_Freezing_Effect;
   end Needs_Discriminant_Generic;

   function Is_Legal_Discriminant_Generic
     (Status : Disc_Gen.Discriminant_Generic_Status) return Boolean is
   begin
      return Status in Disc_Gen.Discriminant_Generic_Legal_Record_Type_Accepted |
                       Disc_Gen.Discriminant_Generic_Legal_Discriminant_Constraint_Accepted |
                       Disc_Gen.Discriminant_Generic_Legal_Discriminant_Default_Accepted |
                       Disc_Gen.Discriminant_Generic_Legal_Variant_Part_Accepted |
                       Disc_Gen.Discriminant_Generic_Legal_Record_Aggregate_Accepted |
                       Disc_Gen.Discriminant_Generic_Legal_Assignment_Accepted |
                       Disc_Gen.Discriminant_Generic_Legal_Conversion_Accepted |
                       Disc_Gen.Discriminant_Generic_Legal_Return_Accepted |
                       Disc_Gen.Discriminant_Generic_Legal_Allocator_Accepted |
                       Disc_Gen.Discriminant_Generic_Legal_Generic_Actual_Accepted |
                       Disc_Gen.Discriminant_Generic_Legal_Private_Full_View_Accepted |
                       Disc_Gen.Discriminant_Generic_Legal_Generic_Replay_Accepted |
                       Disc_Gen.Discriminant_Generic_Legal_Representation_Clause_Accepted |
                       Disc_Gen.Discriminant_Generic_Legal_Record_Layout_Accepted |
                       Disc_Gen.Discriminant_Generic_Legal_Freezing_Effect_Accepted;
   end Is_Legal_Discriminant_Generic;

   function Legal_Status_For_Kind
     (Kind : Accessibility_Consumer_Context_Kind) return Accessibility_Consumer_Status is
   begin
      case Kind is
         when Accessibility_Consumer_Assignment =>
            return Accessibility_Consumer_Legal_Assignment_Accepted;
         when Accessibility_Consumer_Return_Object =>
            return Accessibility_Consumer_Legal_Return_Object_Accepted;
         when Accessibility_Consumer_Return_Access =>
            return Accessibility_Consumer_Legal_Return_Access_Accepted;
         when Accessibility_Consumer_Conversion =>
            return Accessibility_Consumer_Legal_Conversion_Accepted;
         when Accessibility_Consumer_Access_Conversion =>
            return Accessibility_Consumer_Legal_Access_Conversion_Accepted;
         when Accessibility_Consumer_Allocator =>
            return Accessibility_Consumer_Legal_Allocator_Accepted;
         when Accessibility_Consumer_Access_Discriminant =>
            return Accessibility_Consumer_Legal_Access_Discriminant_Accepted;
         when Accessibility_Consumer_Access_Parameter =>
            return Accessibility_Consumer_Legal_Access_Parameter_Accepted;
         when Accessibility_Consumer_Renaming =>
            return Accessibility_Consumer_Legal_Renaming_Accepted;
         when Accessibility_Consumer_Generic_Replay =>
            return Accessibility_Consumer_Legal_Generic_Replay_Accepted;
         when Accessibility_Consumer_Generic_Actual =>
            return Accessibility_Consumer_Legal_Generic_Actual_Accepted;
         when Accessibility_Consumer_Record_Aggregate =>
            return Accessibility_Consumer_Legal_Record_Aggregate_Accepted;
         when Accessibility_Consumer_Representation_Clause =>
            return Accessibility_Consumer_Legal_Representation_Clause_Accepted;
         when Accessibility_Consumer_Record_Layout =>
            return Accessibility_Consumer_Legal_Record_Layout_Accepted;
         when Accessibility_Consumer_Freezing_Effect =>
            return Accessibility_Consumer_Legal_Freezing_Effect_Accepted;
         when Accessibility_Consumer_Finalization =>
            return Accessibility_Consumer_Legal_Finalization_Accepted;
         when others =>
            return Accessibility_Consumer_Indeterminate;
      end case;
   end Legal_Status_For_Kind;

   function Status_From_Scope
     (Status : Scope.Scope_Legality_Status) return Accessibility_Consumer_Status is
   begin
      case Status is
         when Scope.Scope_Legality_Missing_Master =>
            return Accessibility_Consumer_Missing_Master;
         when Scope.Scope_Legality_Master_Too_Short =>
            return Accessibility_Consumer_Master_Too_Short;
         when Scope.Scope_Legality_Static_Level_Too_Deep =>
            return Accessibility_Consumer_Static_Level_Too_Deep;
         when Scope.Scope_Legality_Dynamic_Level_Unresolved =>
            return Accessibility_Consumer_Dynamic_Level_Unresolved;
         when Scope.Scope_Legality_Anonymous_Access_Level_Unresolved =>
            return Accessibility_Consumer_Anonymous_Access_Level_Unresolved;
         when Scope.Scope_Legality_Anonymous_Access_Level_Too_Deep =>
            return Accessibility_Consumer_Anonymous_Access_Level_Too_Deep;
         when Scope.Scope_Legality_Access_Parameter_Escapes =>
            return Accessibility_Consumer_Access_Parameter_Escapes;
         when Scope.Scope_Legality_Allocator_Master_Unresolved =>
            return Accessibility_Consumer_Allocator_Master_Unresolved;
         when Scope.Scope_Legality_Allocator_Master_Too_Short =>
            return Accessibility_Consumer_Allocator_Master_Too_Short;
         when Scope.Scope_Legality_Allocator_Designated_Subtype_Mismatch =>
            return Accessibility_Consumer_Allocator_Designated_Subtype_Mismatch;
         when Scope.Scope_Legality_Return_Object_Master_Too_Short =>
            return Accessibility_Consumer_Return_Object_Master_Too_Short;
         when Scope.Scope_Legality_Return_Access_Master_Too_Short =>
            return Accessibility_Consumer_Return_Access_Master_Too_Short;
         when Scope.Scope_Legality_Return_Master_Unresolved =>
            return Accessibility_Consumer_Return_Master_Unresolved;
         when Scope.Scope_Legality_Access_Discriminant_Master_Unresolved =>
            return Accessibility_Consumer_Access_Discriminant_Master_Unresolved;
         when Scope.Scope_Legality_Access_Discriminant_Master_Too_Short =>
            return Accessibility_Consumer_Access_Discriminant_Master_Too_Short;
         when Scope.Scope_Legality_Access_Conversion_Level_Too_Deep =>
            return Accessibility_Consumer_Access_Conversion_Level_Too_Deep;
         when Scope.Scope_Legality_Generic_Substitution_Master_Mismatch =>
            return Accessibility_Consumer_Generic_Substitution_Master_Mismatch;
         when Scope.Scope_Legality_Generic_Substitution_Master_Unresolved =>
            return Accessibility_Consumer_Generic_Substitution_Master_Unresolved;
         when Scope.Scope_Legality_Dangling_Renaming_Risk =>
            return Accessibility_Consumer_Dangling_Renaming_Risk;
         when Scope.Scope_Legality_Finalization_Master_Unresolved =>
            return Accessibility_Consumer_Finalization_Master_Unresolved;
         when Scope.Scope_Legality_Finalization_Uses_Expired_Master =>
            return Accessibility_Consumer_Finalization_Uses_Expired_Master;
         when Scope.Scope_Legality_Linked_Accessibility_Precision_Error =>
            return Accessibility_Consumer_Linked_Accessibility_Precision_Error;
         when Scope.Scope_Legality_Linked_Generic_Replay_Error =>
            return Accessibility_Consumer_Linked_Generic_Replay_Error;
         when Scope.Scope_Legality_Linked_Discriminant_Error =>
            return Accessibility_Consumer_Linked_Discriminant_Error;
         when Scope.Scope_Legality_Coverage_Gate_Blocker =>
            return Accessibility_Consumer_Scope_Coverage_Gate_Blocker;
         when Scope.Scope_Legality_Multiple_Blockers =>
            return Accessibility_Consumer_Multiple_Scope_Blockers;
         when Scope.Scope_Legality_Indeterminate |
              Scope.Scope_Legality_Not_Checked =>
            return Accessibility_Consumer_Indeterminate;
         when others =>
            return Accessibility_Consumer_Multiple_Scope_Blockers;
      end case;
   end Status_From_Scope;

   function Status_From_Discriminant_Generic
     (Status : Disc_Gen.Discriminant_Generic_Status) return Accessibility_Consumer_Status is
   begin
      if Disc_Gen.Is_Generic_Representation_Error (Status) then
         if Status in Disc_Gen.Discriminant_Generic_Representation_Flow_Global_Error |
                      Disc_Gen.Discriminant_Generic_Representation_Flow_Depends_Error |
                      Disc_Gen.Discriminant_Generic_Representation_Flow_Propagation_Error |
                      Disc_Gen.Discriminant_Generic_Representation_Flow_Coverage_Blocker |
                      Disc_Gen.Discriminant_Generic_Representation_Flow_Tasking_Error then
            return Accessibility_Consumer_Representation_Flow_Error;
         else
            return Accessibility_Consumer_Generic_Representation_Error;
         end if;
      elsif Disc_Gen.Is_Variant_Error (Status) then
         return Accessibility_Consumer_Discriminant_Variant_Error;
      elsif Disc_Gen.Is_Discriminant_Error (Status) then
         return Accessibility_Consumer_Discriminant_Generic_Error;
      else
         case Status is
            when Disc_Gen.Discriminant_Generic_Missing_Discriminant_Row |
                 Disc_Gen.Discriminant_Generic_Missing_Generic_Representation_Row |
                 Disc_Gen.Discriminant_Generic_Coverage_Gate_Blocker =>
               return Accessibility_Consumer_Discriminant_Generic_Error;
            when Disc_Gen.Discriminant_Generic_Multiple_Generic_Representation_Blockers |
                 Disc_Gen.Discriminant_Generic_Multiple_Discriminant_Blockers =>
               return Accessibility_Consumer_Multiple_Discriminant_Generic_Blockers;
            when Disc_Gen.Discriminant_Generic_Indeterminate |
                 Disc_Gen.Discriminant_Generic_Not_Checked =>
               return Accessibility_Consumer_Indeterminate;
            when others =>
               return Accessibility_Consumer_Discriminant_Generic_Error;
         end case;
      end if;
   end Status_From_Discriminant_Generic;

   function Message_For
     (Status : Accessibility_Consumer_Status;
      Kind   : Accessibility_Consumer_Context_Kind) return String is
   begin
      case Status is
         when Accessibility_Consumer_Legal_Assignment_Accepted |
              Accessibility_Consumer_Legal_Return_Object_Accepted |
              Accessibility_Consumer_Legal_Return_Access_Accepted |
              Accessibility_Consumer_Legal_Conversion_Accepted |
              Accessibility_Consumer_Legal_Access_Conversion_Accepted |
              Accessibility_Consumer_Legal_Allocator_Accepted |
              Accessibility_Consumer_Legal_Access_Discriminant_Accepted |
              Accessibility_Consumer_Legal_Access_Parameter_Accepted |
              Accessibility_Consumer_Legal_Renaming_Accepted |
              Accessibility_Consumer_Legal_Generic_Replay_Accepted |
              Accessibility_Consumer_Legal_Generic_Actual_Accepted |
              Accessibility_Consumer_Legal_Record_Aggregate_Accepted |
              Accessibility_Consumer_Legal_Representation_Clause_Accepted |
              Accessibility_Consumer_Legal_Record_Layout_Accepted |
              Accessibility_Consumer_Legal_Freezing_Effect_Accepted |
              Accessibility_Consumer_Legal_Finalization_Accepted =>
            return "accessibility scope consumer accepted exact master/scope evidence";
         when Accessibility_Consumer_Missing_Scope_Row =>
            return "accessibility consumer lacks exact master/scope graph evidence";
         when Accessibility_Consumer_Missing_Discriminant_Generic_Row =>
            return "accessibility consumer lacks discriminant/generic representation evidence";
         when Accessibility_Consumer_Indeterminate =>
            return "accessibility scope consumer remains indeterminate";
         when others =>
            if Is_Scope_Error (Status) then
               return "accessibility scope graph blocks consumer legality";
            elsif Is_Generic_Error (Status) or else Is_Representation_Error (Status) then
               return "generic/discriminant representation evidence blocks accessibility consumer";
            else
               return "accessibility consumer semantic blocker";
            end if;
      end case;
   end Message_For;

   function Detail_For (Info : Accessibility_Consumer_Info) return String is
   begin
      return "kind=" & Accessibility_Consumer_Context_Kind'Image (Info.Kind) &
        ", scope_status=" & Scope.Scope_Legality_Status'Image (Info.Scope_Status) &
        ", discriminant_generic_status=" &
        Disc_Gen.Discriminant_Generic_Status'Image (Info.Discriminant_Generic_Status);
   end Detail_For;

   function Compute_Fingerprint (Info : Accessibility_Consumer_Info) return Natural is
      R : Natural := Natural (Info.Id);
   begin
      R := Mix (R, Natural (Info.Context));
      R := Mix (R, Accessibility_Consumer_Context_Kind'Pos (Info.Kind));
      R := Mix (R, Accessibility_Consumer_Status'Pos (Info.Status));
      R := Mix (R, Natural (Info.Node));
      R := Mix (R, Text_Fingerprint (Info.Object_Name));
      R := Mix (R, Text_Fingerprint (Info.Type_Name));
      R := Mix (R, Text_Fingerprint (Info.Generic_Unit_Name));
      R := Mix (R, Text_Fingerprint (Info.Instance_Name));
      R := Mix (R, Natural (Info.Scope_Row));
      R := Mix (R, Scope.Scope_Legality_Status'Pos (Info.Scope_Status));
      R := Mix (R, Info.Scope_Matches);
      R := Mix (R, Natural (Info.Discriminant_Generic_Row));
      R := Mix (R, Disc_Gen.Discriminant_Generic_Status'Pos (Info.Discriminant_Generic_Status));
      R := Mix (R, Info.Discriminant_Generic_Matches);
      R := Mix (R, Info.Source_Fingerprint);
      R := Mix (R, Info.Scope_Fingerprint);
      R := Mix (R, Info.Consumer_Fingerprint);
      return R;
   end Compute_Fingerprint;

   procedure Clear (Model : in out Accessibility_Consumer_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Accessibility_Consumer_Context_Model;
      Info  : Accessibility_Consumer_Context_Info) is
   begin
      Model.Contexts.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Accessibility_Consumer_Context_Kind'Pos (Info.Kind));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Node));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Source_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Scope_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Consumer_Fingerprint);
   end Add_Context;

   function Context_Count (Model : Accessibility_Consumer_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Accessibility_Consumer_Context_Model;
      Index : Positive) return Accessibility_Consumer_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Accessibility_Consumer_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Build
     (Contexts : Accessibility_Consumer_Context_Model) return Accessibility_Consumer_Model is
      Model : Accessibility_Consumer_Model;
      Row   : Accessibility_Consumer_Info;
      Next  : Accessibility_Consumer_Row_Id := 1;
   begin
      for C of Contexts.Contexts loop
         Row := (others => <>);
         Row.Id := Next;
         Row.Context := C.Id;
         Row.Kind := C.Kind;
         Row.Node := C.Node;
         Row.Object_Name := C.Object_Name;
         Row.Type_Name := C.Type_Name;
         Row.Generic_Unit_Name := C.Generic_Unit_Name;
         Row.Instance_Name := C.Instance_Name;
         Row.Scope_Row := C.Scope_Row;
         Row.Scope_Status := C.Scope_Status;
         Row.Scope_Matches := C.Scope_Matches;
         Row.Discriminant_Generic_Row := C.Discriminant_Generic_Row;
         Row.Discriminant_Generic_Status := C.Discriminant_Generic_Status;
         Row.Discriminant_Generic_Matches := C.Discriminant_Generic_Matches;
         Row.Start_Line := C.Start_Line;
         Row.Start_Column := C.Start_Column;
         Row.End_Line := C.End_Line;
         Row.End_Column := C.End_Column;
         Row.Source_Fingerprint := C.Source_Fingerprint;
         Row.Scope_Fingerprint := C.Scope_Fingerprint;
         Row.Consumer_Fingerprint := C.Consumer_Fingerprint;

         if C.Scope_Matches = 0 or else C.Scope_Row = Scope.No_Scope_Legality then
            Row.Status := Accessibility_Consumer_Missing_Scope_Row;
         elsif not Is_Legal_Scope (C.Scope_Status) then
            Row.Status := Status_From_Scope (C.Scope_Status);
         elsif Needs_Discriminant_Generic (C.Kind)
           and then (C.Discriminant_Generic_Matches = 0
                     or else C.Discriminant_Generic_Row = Disc_Gen.No_Discriminant_Generic_Row)
         then
            Row.Status := Accessibility_Consumer_Missing_Discriminant_Generic_Row;
         elsif Needs_Discriminant_Generic (C.Kind)
           and then not Is_Legal_Discriminant_Generic (C.Discriminant_Generic_Status)
         then
            Row.Status := Status_From_Discriminant_Generic (C.Discriminant_Generic_Status);
         else
            Row.Status := Legal_Status_For_Kind (C.Kind);
         end if;

         Row.Message := To_Unbounded_String (Message_For (Row.Status, Row.Kind));
         Row.Detail := To_Unbounded_String (Detail_For (Row));
         Row.Fingerprint := Compute_Fingerprint (Row);
         Model.Rows.Append (Row);
         Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Row.Fingerprint);
         Next := Next + 1;
      end loop;
      return Model;
   end Build;

   function Row_Count (Model : Accessibility_Consumer_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : Accessibility_Consumer_Model;
      Index : Positive) return Accessibility_Consumer_Info is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function First_For_Node
     (Model : Accessibility_Consumer_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Accessibility_Consumer_Info is
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Accessibility_Consumer_Model;
      Status : Accessibility_Consumer_Status) return Accessibility_Consumer_Set is
      Result : Accessibility_Consumer_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Result.Items.Append (Row);
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Accessibility_Consumer_Model;
      Kind  : Accessibility_Consumer_Context_Kind) return Accessibility_Consumer_Set is
      Result : Accessibility_Consumer_Set;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Result.Items.Append (Row);
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Kind;

   function Rows_For_Object
     (Model       : Accessibility_Consumer_Model;
      Object_Name : String) return Accessibility_Consumer_Set is
      Result : Accessibility_Consumer_Set;
   begin
      for Row of Model.Rows loop
         if S (Row.Object_Name) = Object_Name then
            Result.Items.Append (Row);
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Object;

   function Rows_For_Instance
     (Model         : Accessibility_Consumer_Model;
      Instance_Name : String) return Accessibility_Consumer_Set is
      Result : Accessibility_Consumer_Set;
   begin
      for Row of Model.Rows loop
         if S (Row.Instance_Name) = Instance_Name then
            Result.Items.Append (Row);
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Instance;

   function Set_Count (Results : Accessibility_Consumer_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Set_Count;

   function Set_At
     (Results : Accessibility_Consumer_Set;
      Index   : Positive) return Accessibility_Consumer_Info is
   begin
      return Results.Items.Element (Index);
   end Set_At;

   function Count_Status
     (Model  : Accessibility_Consumer_Model;
      Status : Accessibility_Consumer_Status) return Natural is
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
     (Model : Accessibility_Consumer_Model;
      Kind  : Accessibility_Consumer_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Has_Confident_Consumer (Info : Accessibility_Consumer_Info) return Boolean is
   begin
      return Info.Status in Accessibility_Consumer_Legal_Assignment_Accepted |
                            Accessibility_Consumer_Legal_Return_Object_Accepted |
                            Accessibility_Consumer_Legal_Return_Access_Accepted |
                            Accessibility_Consumer_Legal_Conversion_Accepted |
                            Accessibility_Consumer_Legal_Access_Conversion_Accepted |
                            Accessibility_Consumer_Legal_Allocator_Accepted |
                            Accessibility_Consumer_Legal_Access_Discriminant_Accepted |
                            Accessibility_Consumer_Legal_Access_Parameter_Accepted |
                            Accessibility_Consumer_Legal_Renaming_Accepted |
                            Accessibility_Consumer_Legal_Generic_Replay_Accepted |
                            Accessibility_Consumer_Legal_Generic_Actual_Accepted |
                            Accessibility_Consumer_Legal_Record_Aggregate_Accepted |
                            Accessibility_Consumer_Legal_Representation_Clause_Accepted |
                            Accessibility_Consumer_Legal_Record_Layout_Accepted |
                            Accessibility_Consumer_Legal_Freezing_Effect_Accepted |
                            Accessibility_Consumer_Legal_Finalization_Accepted;
   end Has_Confident_Consumer;

   function Legal_Count (Model : Accessibility_Consumer_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Has_Confident_Consumer (Row) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Legal_Count;

   function Is_Scope_Error (Status : Accessibility_Consumer_Status) return Boolean is
   begin
      return Status in Accessibility_Consumer_Missing_Scope_Row |
                       Accessibility_Consumer_Missing_Master |
                       Accessibility_Consumer_Master_Too_Short |
                       Accessibility_Consumer_Static_Level_Too_Deep |
                       Accessibility_Consumer_Dynamic_Level_Unresolved |
                       Accessibility_Consumer_Anonymous_Access_Level_Unresolved |
                       Accessibility_Consumer_Anonymous_Access_Level_Too_Deep |
                       Accessibility_Consumer_Access_Parameter_Escapes |
                       Accessibility_Consumer_Allocator_Master_Unresolved |
                       Accessibility_Consumer_Allocator_Master_Too_Short |
                       Accessibility_Consumer_Allocator_Designated_Subtype_Mismatch |
                       Accessibility_Consumer_Return_Object_Master_Too_Short |
                       Accessibility_Consumer_Return_Access_Master_Too_Short |
                       Accessibility_Consumer_Return_Master_Unresolved |
                       Accessibility_Consumer_Access_Discriminant_Master_Unresolved |
                       Accessibility_Consumer_Access_Discriminant_Master_Too_Short |
                       Accessibility_Consumer_Access_Conversion_Level_Too_Deep |
                       Accessibility_Consumer_Generic_Substitution_Master_Mismatch |
                       Accessibility_Consumer_Generic_Substitution_Master_Unresolved |
                       Accessibility_Consumer_Dangling_Renaming_Risk |
                       Accessibility_Consumer_Finalization_Master_Unresolved |
                       Accessibility_Consumer_Finalization_Uses_Expired_Master |
                       Accessibility_Consumer_Linked_Accessibility_Precision_Error |
                       Accessibility_Consumer_Linked_Generic_Replay_Error |
                       Accessibility_Consumer_Linked_Discriminant_Error |
                       Accessibility_Consumer_Scope_Coverage_Gate_Blocker |
                       Accessibility_Consumer_Multiple_Scope_Blockers;
   end Is_Scope_Error;

   function Is_Return_Error (Status : Accessibility_Consumer_Status) return Boolean is
   begin
      return Status in Accessibility_Consumer_Return_Object_Master_Too_Short |
                       Accessibility_Consumer_Return_Access_Master_Too_Short |
                       Accessibility_Consumer_Return_Master_Unresolved;
   end Is_Return_Error;

   function Is_Allocator_Error (Status : Accessibility_Consumer_Status) return Boolean is
   begin
      return Status in Accessibility_Consumer_Allocator_Master_Unresolved |
                       Accessibility_Consumer_Allocator_Master_Too_Short |
                       Accessibility_Consumer_Allocator_Designated_Subtype_Mismatch;
   end Is_Allocator_Error;

   function Is_Access_Discriminant_Error (Status : Accessibility_Consumer_Status) return Boolean is
   begin
      return Status in Accessibility_Consumer_Access_Discriminant_Master_Unresolved |
                       Accessibility_Consumer_Access_Discriminant_Master_Too_Short |
                       Accessibility_Consumer_Discriminant_Generic_Error |
                       Accessibility_Consumer_Discriminant_Variant_Error |
                       Accessibility_Consumer_Missing_Discriminant_Generic_Row;
   end Is_Access_Discriminant_Error;

   function Is_Generic_Error (Status : Accessibility_Consumer_Status) return Boolean is
   begin
      return Status in Accessibility_Consumer_Generic_Substitution_Master_Mismatch |
                       Accessibility_Consumer_Generic_Substitution_Master_Unresolved |
                       Accessibility_Consumer_Linked_Generic_Replay_Error |
                       Accessibility_Consumer_Generic_Representation_Error |
                       Accessibility_Consumer_Multiple_Discriminant_Generic_Blockers;
   end Is_Generic_Error;

   function Is_Representation_Error (Status : Accessibility_Consumer_Status) return Boolean is
   begin
      return Status in Accessibility_Consumer_Representation_Flow_Error |
                       Accessibility_Consumer_Generic_Representation_Error |
                       Accessibility_Consumer_Missing_Discriminant_Generic_Row;
   end Is_Representation_Error;

   function Error_Count (Model : Accessibility_Consumer_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if not Has_Confident_Consumer (Row)
           and then Row.Status /= Accessibility_Consumer_Indeterminate
           and then Row.Status /= Accessibility_Consumer_Not_Checked
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Error_Count;

   function Scope_Error_Count (Model : Accessibility_Consumer_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Scope_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Scope_Error_Count;

   function Return_Error_Count (Model : Accessibility_Consumer_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Return_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Return_Error_Count;

   function Allocator_Error_Count (Model : Accessibility_Consumer_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Allocator_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Allocator_Error_Count;

   function Access_Discriminant_Error_Count (Model : Accessibility_Consumer_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Access_Discriminant_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Access_Discriminant_Error_Count;

   function Generic_Error_Count (Model : Accessibility_Consumer_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Generic_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Generic_Error_Count;

   function Representation_Error_Count (Model : Accessibility_Consumer_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Representation_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Representation_Error_Count;

   function Indeterminate_Count (Model : Accessibility_Consumer_Model) return Natural is
   begin
      return Count_Status (Model, Accessibility_Consumer_Indeterminate);
   end Indeterminate_Count;

   function Fingerprint (Model : Accessibility_Consumer_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Accessibility_Scope_Consumer_Legality;
