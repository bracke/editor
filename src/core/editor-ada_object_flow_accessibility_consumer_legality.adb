with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Object_Flow_Accessibility_Consumer_Legality is


   use type Access_Consumers.Accessibility_Consumer_Row_Id;
   use type Access_Consumers.Accessibility_Consumer_Context_Kind;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   function Mix (A, B : Natural) return Natural is
      type Hash_Value is mod 2 ** 32;
      Mixed : constant Hash_Value :=
        (Hash_Value (A) * 1_315_423_911) xor (Hash_Value (B) + 2_654_435_761);
   begin
      return Natural (Mixed mod Hash_Value (2_147_483_647));
   end Mix;

   function S (Value : Ada.Strings.Unbounded.Unbounded_String) return String is
   begin
      return Ada.Strings.Unbounded.To_String (Value);
   end S;

   function Text_Fingerprint (Value : Ada.Strings.Unbounded.Unbounded_String) return Natural is
      R : Natural := 0;
      T : constant String := S (Value);
   begin
      for Ch of T loop
         R := Mix (R, Character'Pos (Ch));
      end loop;
      return R;
   end Text_Fingerprint;

   function Is_Legal_Accessibility
     (Status : Access_Consumers.Accessibility_Consumer_Status) return Boolean is
   begin
      return Access_Consumers.Has_Confident_Consumer
        ((Id => Access_Consumers.No_Accessibility_Consumer_Row,
          Context => Access_Consumers.No_Accessibility_Consumer_Row,
          Kind => Access_Consumers.Accessibility_Consumer_Unknown,
          Status => Status,
          others => <>));
   end Is_Legal_Accessibility;

   function Expected_Accessibility_Kind
     (Kind : Object_Flow_Context_Kind)
      return Access_Consumers.Accessibility_Consumer_Context_Kind is
   begin
      case Kind is
         when Object_Flow_Assignment |
              Object_Flow_Object_Initialization |
              Object_Flow_Component_Initialization =>
            return Access_Consumers.Accessibility_Consumer_Assignment;
         when Object_Flow_Return_Object =>
            return Access_Consumers.Accessibility_Consumer_Return_Object;
         when Object_Flow_Return_Access =>
            return Access_Consumers.Accessibility_Consumer_Return_Access;
         when Object_Flow_Conversion |
              Object_Flow_Qualified_Expression =>
            return Access_Consumers.Accessibility_Consumer_Conversion;
         when Object_Flow_Access_Conversion =>
            return Access_Consumers.Accessibility_Consumer_Access_Conversion;
         when Object_Flow_Allocator =>
            return Access_Consumers.Accessibility_Consumer_Allocator;
         when Object_Flow_Access_Discriminant =>
            return Access_Consumers.Accessibility_Consumer_Access_Discriminant;
         when Object_Flow_Record_Aggregate |
              Object_Flow_Array_Aggregate =>
            return Access_Consumers.Accessibility_Consumer_Record_Aggregate;
         when Object_Flow_Renaming =>
            return Access_Consumers.Accessibility_Consumer_Renaming;
         when Object_Flow_Generic_Actual =>
            return Access_Consumers.Accessibility_Consumer_Generic_Actual;
         when Object_Flow_Generic_Replay =>
            return Access_Consumers.Accessibility_Consumer_Generic_Replay;
         when Object_Flow_Finalization =>
            return Access_Consumers.Accessibility_Consumer_Finalization;
         when Object_Flow_Unknown =>
            return Access_Consumers.Accessibility_Consumer_Unknown;
      end case;
   end Expected_Accessibility_Kind;

   function Legal_Status_For_Kind (Kind : Object_Flow_Context_Kind) return Object_Flow_Status is
   begin
      case Kind is
         when Object_Flow_Assignment =>
            return Object_Flow_Legal_Assignment_Accepted;
         when Object_Flow_Object_Initialization |
              Object_Flow_Component_Initialization =>
            return Object_Flow_Legal_Initialization_Accepted;
         when Object_Flow_Return_Object =>
            return Object_Flow_Legal_Return_Object_Accepted;
         when Object_Flow_Return_Access =>
            return Object_Flow_Legal_Return_Access_Accepted;
         when Object_Flow_Conversion =>
            return Object_Flow_Legal_Conversion_Accepted;
         when Object_Flow_Access_Conversion =>
            return Object_Flow_Legal_Access_Conversion_Accepted;
         when Object_Flow_Qualified_Expression =>
            return Object_Flow_Legal_Qualified_Expression_Accepted;
         when Object_Flow_Allocator =>
            return Object_Flow_Legal_Allocator_Accepted;
         when Object_Flow_Access_Discriminant =>
            return Object_Flow_Legal_Access_Discriminant_Accepted;
         when Object_Flow_Record_Aggregate |
              Object_Flow_Array_Aggregate =>
            return Object_Flow_Legal_Aggregate_Accepted;
         when Object_Flow_Renaming =>
            return Object_Flow_Legal_Renaming_Accepted;
         when Object_Flow_Generic_Actual =>
            return Object_Flow_Legal_Generic_Actual_Accepted;
         when Object_Flow_Generic_Replay =>
            return Object_Flow_Legal_Generic_Replay_Accepted;
         when Object_Flow_Finalization =>
            return Object_Flow_Legal_Finalization_Accepted;
         when Object_Flow_Unknown =>
            return Object_Flow_Indeterminate;
      end case;
   end Legal_Status_For_Kind;

   function Status_From_Accessibility
     (Status : Access_Consumers.Accessibility_Consumer_Status) return Object_Flow_Status is
   begin
      case Status is
         when Access_Consumers.Accessibility_Consumer_Return_Access_Master_Too_Short =>
            return Object_Flow_Return_Access_Master_Too_Short;
         when Access_Consumers.Accessibility_Consumer_Return_Object_Master_Too_Short =>
            return Object_Flow_Return_Object_Master_Too_Short;
         when Access_Consumers.Accessibility_Consumer_Return_Master_Unresolved =>
            return Object_Flow_Return_Master_Unresolved;
         when Access_Consumers.Accessibility_Consumer_Allocator_Master_Too_Short =>
            return Object_Flow_Allocator_Master_Too_Short;
         when Access_Consumers.Accessibility_Consumer_Allocator_Master_Unresolved =>
            return Object_Flow_Allocator_Master_Unresolved;
         when Access_Consumers.Accessibility_Consumer_Allocator_Designated_Subtype_Mismatch =>
            return Object_Flow_Allocator_Designated_Subtype_Mismatch;
         when Access_Consumers.Accessibility_Consumer_Access_Conversion_Level_Too_Deep =>
            return Object_Flow_Access_Conversion_Level_Too_Deep;
         when Access_Consumers.Accessibility_Consumer_Access_Discriminant_Master_Too_Short =>
            return Object_Flow_Access_Discriminant_Master_Too_Short;
         when Access_Consumers.Accessibility_Consumer_Access_Discriminant_Master_Unresolved =>
            return Object_Flow_Access_Discriminant_Master_Unresolved;
         when Access_Consumers.Accessibility_Consumer_Access_Parameter_Escapes =>
            return Object_Flow_Access_Parameter_Escapes;
         when Access_Consumers.Accessibility_Consumer_Anonymous_Access_Level_Too_Deep =>
            return Object_Flow_Anonymous_Access_Level_Too_Deep;
         when Access_Consumers.Accessibility_Consumer_Anonymous_Access_Level_Unresolved =>
            return Object_Flow_Anonymous_Access_Level_Unresolved;
         when Access_Consumers.Accessibility_Consumer_Static_Level_Too_Deep =>
            return Object_Flow_Static_Level_Too_Deep;
         when Access_Consumers.Accessibility_Consumer_Dynamic_Level_Unresolved =>
            return Object_Flow_Dynamic_Level_Unresolved;
         when Access_Consumers.Accessibility_Consumer_Generic_Substitution_Master_Mismatch =>
            return Object_Flow_Generic_Substitution_Master_Mismatch;
         when Access_Consumers.Accessibility_Consumer_Generic_Substitution_Master_Unresolved =>
            return Object_Flow_Generic_Substitution_Master_Unresolved;
         when Access_Consumers.Accessibility_Consumer_Dangling_Renaming_Risk =>
            return Object_Flow_Dangling_Renaming_Risk;
         when Access_Consumers.Accessibility_Consumer_Finalization_Master_Unresolved =>
            return Object_Flow_Finalization_Master_Unresolved;
         when Access_Consumers.Accessibility_Consumer_Finalization_Uses_Expired_Master =>
            return Object_Flow_Finalization_Uses_Expired_Master;
         when Access_Consumers.Accessibility_Consumer_Discriminant_Variant_Error |
              Access_Consumers.Accessibility_Consumer_Discriminant_Generic_Error =>
            return Object_Flow_Discriminant_Variant_Blocker;
         when Access_Consumers.Accessibility_Consumer_Generic_Representation_Error =>
            return Object_Flow_Generic_Representation_Blocker;
         when Access_Consumers.Accessibility_Consumer_Representation_Flow_Error =>
            return Object_Flow_Representation_Flow_Blocker;
         when Access_Consumers.Accessibility_Consumer_Scope_Coverage_Gate_Blocker =>
            return Object_Flow_Coverage_Gate_Blocker;
         when Access_Consumers.Accessibility_Consumer_Linked_Accessibility_Precision_Error =>
            return Object_Flow_Linked_Accessibility_Error;
         when Access_Consumers.Accessibility_Consumer_Linked_Generic_Replay_Error =>
            return Object_Flow_Linked_Generic_Replay_Error;
         when Access_Consumers.Accessibility_Consumer_Multiple_Scope_Blockers |
              Access_Consumers.Accessibility_Consumer_Multiple_Discriminant_Generic_Blockers =>
            return Object_Flow_Multiple_Accessibility_Blockers;
         when Access_Consumers.Accessibility_Consumer_Indeterminate |
              Access_Consumers.Accessibility_Consumer_Not_Checked =>
            return Object_Flow_Indeterminate;
         when others =>
            return Object_Flow_Multiple_Accessibility_Blockers;
      end case;
   end Status_From_Accessibility;

   function Message_For
     (Status : Object_Flow_Status;
      Kind   : Object_Flow_Context_Kind) return String is
      pragma Unreferenced (Kind);
   begin
      case Status is
         when Object_Flow_Legal_Assignment_Accepted |
              Object_Flow_Legal_Initialization_Accepted |
              Object_Flow_Legal_Return_Object_Accepted |
              Object_Flow_Legal_Return_Access_Accepted |
              Object_Flow_Legal_Conversion_Accepted |
              Object_Flow_Legal_Access_Conversion_Accepted |
              Object_Flow_Legal_Qualified_Expression_Accepted |
              Object_Flow_Legal_Allocator_Accepted |
              Object_Flow_Legal_Access_Discriminant_Accepted |
              Object_Flow_Legal_Aggregate_Accepted |
              Object_Flow_Legal_Renaming_Accepted |
              Object_Flow_Legal_Generic_Actual_Accepted |
              Object_Flow_Legal_Generic_Replay_Accepted |
              Object_Flow_Legal_Finalization_Accepted =>
            return "object-flow legality accepted exact accessibility evidence";
         when Object_Flow_Missing_Accessibility_Consumer_Row =>
            return "object-flow legality lacks exact accessibility consumer evidence";
         when Object_Flow_Mismatched_Accessibility_Consumer_Kind =>
            return "object-flow legality uses mismatched accessibility consumer evidence";
         when Object_Flow_Preserved_Object_Flow_Error =>
            return "object-flow legality preserves original semantic error";
         when Object_Flow_Indeterminate =>
            return "object-flow accessibility consumer remains indeterminate";
         when others =>
            return "accessibility scope evidence blocks object-flow legality";
      end case;
   end Message_For;

   function Detail_For (Info : Object_Flow_Info) return String is
   begin
      return "kind=" & Object_Flow_Context_Kind'Image (Info.Kind) &
        ", accessibility_kind=" &
        Access_Consumers.Accessibility_Consumer_Context_Kind'Image (Info.Accessibility_Kind) &
        ", accessibility_status=" &
        Access_Consumers.Accessibility_Consumer_Status'Image (Info.Accessibility_Status);
   end Detail_For;

   function Compute_Fingerprint (Info : Object_Flow_Info) return Natural is
      R : Natural := Natural (Info.Id);
   begin
      R := Mix (R, Natural (Info.Context));
      R := Mix (R, Object_Flow_Context_Kind'Pos (Info.Kind));
      R := Mix (R, Object_Flow_Status'Pos (Info.Status));
      R := Mix (R, Natural (Info.Node));
      R := Mix (R, Text_Fingerprint (Info.Object_Name));
      R := Mix (R, Text_Fingerprint (Info.Target_Type));
      R := Mix (R, Text_Fingerprint (Info.Source_Type));
      R := Mix (R, Text_Fingerprint (Info.Generic_Unit_Name));
      R := Mix (R, Text_Fingerprint (Info.Instance_Name));
      R := Mix (R, Natural (Info.Accessibility_Row));
      R := Mix (R, Access_Consumers.Accessibility_Consumer_Status'Pos (Info.Accessibility_Status));
      R := Mix (R, Access_Consumers.Accessibility_Consumer_Context_Kind'Pos (Info.Accessibility_Kind));
      R := Mix (R, Info.Accessibility_Matches);
      R := Mix (R, Info.Source_Fingerprint);
      R := Mix (R, Info.Accessibility_Fingerprint);
      R := Mix (R, Info.Object_Flow_Fingerprint);
      if Info.Original_Object_Flow_Error then
         R := Mix (R, 1);
      end if;
      return R;
   end Compute_Fingerprint;

   procedure Clear (Model : in out Object_Flow_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Object_Flow_Context_Model;
      Info  : Object_Flow_Context_Info) is
   begin
      Model.Contexts.Append (Info);
      Model.Result_Fingerprint := Mix
        (Model.Result_Fingerprint,
         Natural (Info.Id) + Natural (Info.Node) + Info.Source_Fingerprint +
         Info.Accessibility_Fingerprint + Info.Object_Flow_Fingerprint);
   end Add_Context;

   function Context_Count (Model : Object_Flow_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Object_Flow_Context_Model;
      Index : Positive) return Object_Flow_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Object_Flow_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Build
     (Contexts : Object_Flow_Context_Model) return Object_Flow_Model is
      Result : Object_Flow_Model;
      Row    : Object_Flow_Info;
      Status : Object_Flow_Status;
      Expected : Access_Consumers.Accessibility_Consumer_Context_Kind;
   begin
      for Index in 1 .. Context_Count (Contexts) loop
         declare
            C : constant Object_Flow_Context_Info := Context_At (Contexts, Index);
         begin
            if C.Original_Object_Flow_Error then
               Status := Object_Flow_Preserved_Object_Flow_Error;
            elsif C.Accessibility_Row = Access_Consumers.No_Accessibility_Consumer_Row or else
                  C.Accessibility_Matches = 0 then
               Status := Object_Flow_Missing_Accessibility_Consumer_Row;
            else
               Expected := Expected_Accessibility_Kind (C.Kind);
               if Expected /= Access_Consumers.Accessibility_Consumer_Unknown and then
                 C.Accessibility_Kind /= Expected
               then
                  Status := Object_Flow_Mismatched_Accessibility_Consumer_Kind;
               elsif Is_Legal_Accessibility (C.Accessibility_Status) then
                  Status := Legal_Status_For_Kind (C.Kind);
               else
                  Status := Status_From_Accessibility (C.Accessibility_Status);
               end if;
            end if;

            Row := (Id => Object_Flow_Row_Id (Index),
                    Context => C.Id,
                    Kind => C.Kind,
                    Status => Status,
                    Node => C.Node,
                    Object_Name => C.Object_Name,
                    Target_Type => C.Target_Type,
                    Source_Type => C.Source_Type,
                    Generic_Unit_Name => C.Generic_Unit_Name,
                    Instance_Name => C.Instance_Name,
                    Message => To_Unbounded_String (Message_For (Status, C.Kind)),
                    Detail => Null_Unbounded_String,
                    Accessibility_Row => C.Accessibility_Row,
                    Accessibility_Status => C.Accessibility_Status,
                    Accessibility_Kind => C.Accessibility_Kind,
                    Accessibility_Matches => C.Accessibility_Matches,
                    Original_Object_Flow_Error => C.Original_Object_Flow_Error,
                    Start_Line => C.Start_Line,
                    Start_Column => C.Start_Column,
                    End_Line => C.End_Line,
                    End_Column => C.End_Column,
                    Source_Fingerprint => C.Source_Fingerprint,
                    Accessibility_Fingerprint => C.Accessibility_Fingerprint,
                    Object_Flow_Fingerprint => C.Object_Flow_Fingerprint,
                    Fingerprint => 0);
            Row.Detail := To_Unbounded_String (Detail_For (Row));
            Row.Fingerprint := Compute_Fingerprint (Row);
            Result.Rows.Append (Row);
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, Row.Fingerprint);
         end;
      end loop;
      return Result;
   end Build;

   function Row_Count (Model : Object_Flow_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : Object_Flow_Model;
      Index : Positive) return Object_Flow_Info is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function First_For_Node
     (Model : Object_Flow_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Object_Flow_Info is
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Object_Flow_Model;
      Status : Object_Flow_Status) return Object_Flow_Set is
      Result : Object_Flow_Set;
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
     (Model : Object_Flow_Model;
      Kind  : Object_Flow_Context_Kind) return Object_Flow_Set is
      Result : Object_Flow_Set;
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
     (Model : Object_Flow_Model;
      Name  : String) return Object_Flow_Set is
      Result : Object_Flow_Set;
   begin
      for Row of Model.Rows loop
         if S (Row.Object_Name) = Name then
            Result.Items.Append (Row);
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Object;

   function Rows_For_Instance
     (Model : Object_Flow_Model;
      Name  : String) return Object_Flow_Set is
      Result : Object_Flow_Set;
   begin
      for Row of Model.Rows loop
         if S (Row.Instance_Name) = Name then
            Result.Items.Append (Row);
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Instance;

   function Set_Count (Results : Object_Flow_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Set_Count;

   function Set_At
     (Results : Object_Flow_Set;
      Index   : Positive) return Object_Flow_Info is
   begin
      return Results.Items.Element (Index);
   end Set_At;

   function Count_Status
     (Model  : Object_Flow_Model;
      Status : Object_Flow_Status) return Natural is
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
     (Model : Object_Flow_Model;
      Kind  : Object_Flow_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Has_Confident_Object_Flow (Info : Object_Flow_Info) return Boolean is
   begin
      return Info.Status in Object_Flow_Legal_Assignment_Accepted |
        Object_Flow_Legal_Initialization_Accepted |
        Object_Flow_Legal_Return_Object_Accepted |
        Object_Flow_Legal_Return_Access_Accepted |
        Object_Flow_Legal_Conversion_Accepted |
        Object_Flow_Legal_Access_Conversion_Accepted |
        Object_Flow_Legal_Qualified_Expression_Accepted |
        Object_Flow_Legal_Allocator_Accepted |
        Object_Flow_Legal_Access_Discriminant_Accepted |
        Object_Flow_Legal_Aggregate_Accepted |
        Object_Flow_Legal_Renaming_Accepted |
        Object_Flow_Legal_Generic_Actual_Accepted |
        Object_Flow_Legal_Generic_Replay_Accepted |
        Object_Flow_Legal_Finalization_Accepted;
   end Has_Confident_Object_Flow;

   function Legal_Count (Model : Object_Flow_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Has_Confident_Object_Flow (Row) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Legal_Count;

   function Is_Return_Error (Status : Object_Flow_Status) return Boolean is
   begin
      return Status in Object_Flow_Return_Access_Master_Too_Short |
        Object_Flow_Return_Object_Master_Too_Short |
        Object_Flow_Return_Master_Unresolved;
   end Is_Return_Error;

   function Is_Allocator_Error (Status : Object_Flow_Status) return Boolean is
   begin
      return Status in Object_Flow_Allocator_Master_Too_Short |
        Object_Flow_Allocator_Master_Unresolved |
        Object_Flow_Allocator_Designated_Subtype_Mismatch;
   end Is_Allocator_Error;

   function Is_Access_Error (Status : Object_Flow_Status) return Boolean is
   begin
      return Status in Object_Flow_Access_Conversion_Level_Too_Deep |
        Object_Flow_Access_Discriminant_Master_Too_Short |
        Object_Flow_Access_Discriminant_Master_Unresolved |
        Object_Flow_Access_Parameter_Escapes |
        Object_Flow_Anonymous_Access_Level_Too_Deep |
        Object_Flow_Anonymous_Access_Level_Unresolved |
        Object_Flow_Static_Level_Too_Deep |
        Object_Flow_Dynamic_Level_Unresolved |
        Object_Flow_Linked_Accessibility_Error;
   end Is_Access_Error;

   function Is_Generic_Error (Status : Object_Flow_Status) return Boolean is
   begin
      return Status in Object_Flow_Generic_Substitution_Master_Mismatch |
        Object_Flow_Generic_Substitution_Master_Unresolved |
        Object_Flow_Linked_Generic_Replay_Error |
        Object_Flow_Generic_Representation_Blocker;
   end Is_Generic_Error;

   function Is_Representation_Error (Status : Object_Flow_Status) return Boolean is
   begin
      return Status in Object_Flow_Representation_Flow_Blocker |
        Object_Flow_Generic_Representation_Blocker |
        Object_Flow_Discriminant_Variant_Blocker;
   end Is_Representation_Error;

   function Is_Coverage_Error (Status : Object_Flow_Status) return Boolean is
   begin
      return Status = Object_Flow_Coverage_Gate_Blocker;
   end Is_Coverage_Error;

   function Error_Count (Model : Object_Flow_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if not Has_Confident_Object_Flow (Row) and then
           Row.Status /= Object_Flow_Indeterminate and then
           Row.Status /= Object_Flow_Not_Checked
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Error_Count;

   function Return_Error_Count (Model : Object_Flow_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Return_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Return_Error_Count;

   function Allocator_Error_Count (Model : Object_Flow_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Allocator_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Allocator_Error_Count;

   function Access_Error_Count (Model : Object_Flow_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Access_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Access_Error_Count;

   function Generic_Error_Count (Model : Object_Flow_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Generic_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Generic_Error_Count;

   function Representation_Error_Count (Model : Object_Flow_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Representation_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Representation_Error_Count;

   function Coverage_Error_Count (Model : Object_Flow_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Coverage_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Coverage_Error_Count;

   function Indeterminate_Count (Model : Object_Flow_Model) return Natural is
   begin
      return Count_Status (Model, Object_Flow_Indeterminate);
   end Indeterminate_Count;

   function Fingerprint (Model : Object_Flow_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Object_Flow_Accessibility_Consumer_Legality;
