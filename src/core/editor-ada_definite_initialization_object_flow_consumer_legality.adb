with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Definite_Initialization_Object_Flow_Consumer_Legality is

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Init.Initialization_Context_Kind;
   use type Init.Initialization_Legality_Status;
   use type Obj_Flow.Object_Flow_Context_Kind;
   use type Obj_Flow.Object_Flow_Row_Id;
   use type Obj_Flow.Object_Flow_Status;

   function Mix (A, B : Natural) return Natural is
   begin
      return (A * 16_777_619 + B + 97) mod 2_147_483_647;
   end Mix;

   function Text (Value : Unbounded_String) return String is
   begin
      return To_String (Value);
   end Text;

   function Expected_Object_Flow_Kind
     (Kind : Init.Initialization_Context_Kind)
      return Obj_Flow.Object_Flow_Context_Kind is
   begin
      case Kind is
         when Init.Initialization_Context_Object_Declaration |
              Init.Initialization_Context_Parameter_Out |
              Init.Initialization_Context_Parameter_In_Out =>
            return Obj_Flow.Object_Flow_Object_Initialization;
         when Init.Initialization_Context_Assignment =>
            return Obj_Flow.Object_Flow_Assignment;
         when Init.Initialization_Context_Return |
              Init.Initialization_Context_Extended_Return =>
            return Obj_Flow.Object_Flow_Return_Object;
         when Init.Initialization_Context_Component =>
            return Obj_Flow.Object_Flow_Component_Initialization;
         when Init.Initialization_Context_Aggregate =>
            return Obj_Flow.Object_Flow_Record_Aggregate;
         when Init.Initialization_Context_Finalization_Path =>
            return Obj_Flow.Object_Flow_Finalization;
         when Init.Initialization_Context_Read |
              Init.Initialization_Context_Parameter_In |
              Init.Initialization_Context_Exception_Path |
              Init.Initialization_Context_Loop_Merge |
              Init.Initialization_Context_Branch_Merge |
              Init.Initialization_Context_Unknown =>
            return Obj_Flow.Object_Flow_Unknown;
      end case;
   end Expected_Object_Flow_Kind;

   function Legal_Status_For_Init
     (Status : Init.Initialization_Legality_Status)
      return Initialization_Object_Flow_Status is
   begin
      case Status is
         when Init.Initialization_Legality_Definitely_Initialized =>
            return Initialization_Object_Flow_Legal_Definite_Init_Accepted;
         when Init.Initialization_Legality_Default_Initialized =>
            return Initialization_Object_Flow_Legal_Default_Init_Accepted;
         when Init.Initialization_Legality_Explicitly_Initialized =>
            return Initialization_Object_Flow_Legal_Explicit_Init_Accepted;
         when Init.Initialization_Legality_Component_Initialized =>
            return Initialization_Object_Flow_Legal_Component_Init_Accepted;
         when Init.Initialization_Legality_Out_Parameter_Assigned =>
            return Initialization_Object_Flow_Legal_Out_Parameter_Accepted;
         when Init.Initialization_Legality_Return_Object_Initialized =>
            return Initialization_Object_Flow_Legal_Return_Object_Accepted;
         when Init.Initialization_Legality_Exception_Path_Preserved =>
            return Initialization_Object_Flow_Legal_Exception_Path_Accepted;
         when Init.Initialization_Legality_Finalization_Path_Preserved =>
            return Initialization_Object_Flow_Legal_Finalization_Path_Accepted;
         when others =>
            return Initialization_Object_Flow_Indeterminate;
      end case;
   end Legal_Status_For_Init;

   function Status_From_Initialization
     (Status : Init.Initialization_Legality_Status)
      return Initialization_Object_Flow_Status is
   begin
      case Status is
         when Init.Initialization_Legality_Read_Before_Write =>
            return Initialization_Object_Flow_Preserved_Read_Before_Write;
         when Init.Initialization_Legality_Component_Read_Before_Write =>
            return Initialization_Object_Flow_Preserved_Component_Read_Before_Write;
         when Init.Initialization_Legality_Partial_Component_Initialization =>
            return Initialization_Object_Flow_Preserved_Partial_Component_Init;
         when Init.Initialization_Legality_Out_Parameter_Not_Assigned =>
            return Initialization_Object_Flow_Preserved_Out_Parameter_Not_Assigned;
         when Init.Initialization_Legality_In_Out_Parameter_Conditionally_Assigned =>
            return Initialization_Object_Flow_Preserved_In_Out_Conditional_Assignment;
         when Init.Initialization_Legality_Return_Object_Not_Initialized =>
            return Initialization_Object_Flow_Preserved_Return_Object_Not_Initialized;
         when Init.Initialization_Legality_Branch_Merge_Not_Definite =>
            return Initialization_Object_Flow_Preserved_Branch_Merge_Not_Definite;
         when Init.Initialization_Legality_Loop_Merge_Not_Definite =>
            return Initialization_Object_Flow_Preserved_Loop_Merge_Not_Definite;
         when Init.Initialization_Legality_Exception_Path_Loses_Initialization =>
            return Initialization_Object_Flow_Preserved_Exception_Path_Loss;
         when Init.Initialization_Legality_Finalization_Uses_Uninitialized_Object =>
            return Initialization_Object_Flow_Preserved_Finalization_Uses_Uninitialized;
         when Init.Initialization_Legality_Use_After_Finalization =>
            return Initialization_Object_Flow_Preserved_Use_After_Finalization;
         when Init.Initialization_Legality_Linked_Assignment_Error |
              Init.Initialization_Legality_Linked_Return_Error |
              Init.Initialization_Legality_Linked_Control_Flow_Error |
              Init.Initialization_Legality_Linked_Exception_Finalization_Error |
              Init.Initialization_Legality_Linked_Closure_Error =>
            return Initialization_Object_Flow_Preserved_Linked_Initialization_Error;
         when Init.Initialization_Legality_Indeterminate |
              Init.Initialization_Legality_Not_Checked =>
            return Initialization_Object_Flow_Indeterminate;
         when others =>
            return Legal_Status_For_Init (Status);
      end case;
   end Status_From_Initialization;

   function Status_From_Object_Flow
     (Status : Obj_Flow.Object_Flow_Status)
      return Initialization_Object_Flow_Status is
   begin
      if Obj_Flow.Is_Return_Error (Status) then
         return Initialization_Object_Flow_Return_Lifetime_Blocker;
      elsif Obj_Flow.Is_Allocator_Error (Status) then
         return Initialization_Object_Flow_Allocator_Lifetime_Blocker;
      elsif Obj_Flow.Is_Access_Error (Status) then
         return Initialization_Object_Flow_Access_Lifetime_Blocker;
      elsif Obj_Flow.Is_Generic_Error (Status) then
         return Initialization_Object_Flow_Generic_Lifetime_Blocker;
      elsif Status = Obj_Flow.Object_Flow_Finalization_Master_Unresolved or else
        Status = Obj_Flow.Object_Flow_Finalization_Uses_Expired_Master
      then
         return Initialization_Object_Flow_Access_Lifetime_Blocker;
      elsif Status = Obj_Flow.Object_Flow_Discriminant_Variant_Blocker then
         return Initialization_Object_Flow_Discriminant_Variant_Blocker;
      elsif Obj_Flow.Is_Representation_Error (Status) then
         return Initialization_Object_Flow_Representation_Blocker;
      elsif Obj_Flow.Is_Coverage_Error (Status) then
         return Initialization_Object_Flow_Coverage_Blocker;
      elsif Status = Obj_Flow.Object_Flow_Linked_Accessibility_Error then
         return Initialization_Object_Flow_Linked_Accessibility_Blocker;
      elsif Status = Obj_Flow.Object_Flow_Linked_Generic_Replay_Error then
         return Initialization_Object_Flow_Linked_Generic_Replay_Blocker;
      elsif Status = Obj_Flow.Object_Flow_Multiple_Accessibility_Blockers then
         return Initialization_Object_Flow_Multiple_Object_Flow_Blockers;
      elsif Status = Obj_Flow.Object_Flow_Preserved_Object_Flow_Error then
         return Initialization_Object_Flow_Multiple_Object_Flow_Blockers;
      else
         return Initialization_Object_Flow_Indeterminate;
      end if;
   end Status_From_Object_Flow;

   function Status_For
     (Info : Initialization_Object_Flow_Context_Info)
      return Initialization_Object_Flow_Status is
      Expected : constant Obj_Flow.Object_Flow_Context_Kind :=
        Expected_Object_Flow_Kind (Info.Kind);
   begin
      if Status_From_Initialization (Info.Initialization_Status) not in
        Initialization_Object_Flow_Legal_Definite_Init_Accepted |
        Initialization_Object_Flow_Legal_Default_Init_Accepted |
        Initialization_Object_Flow_Legal_Explicit_Init_Accepted |
        Initialization_Object_Flow_Legal_Component_Init_Accepted |
        Initialization_Object_Flow_Legal_Out_Parameter_Accepted |
        Initialization_Object_Flow_Legal_Return_Object_Accepted |
        Initialization_Object_Flow_Legal_Exception_Path_Accepted |
        Initialization_Object_Flow_Legal_Finalization_Path_Accepted |
        Initialization_Object_Flow_Indeterminate
      then
         return Status_From_Initialization (Info.Initialization_Status);
      end if;

      if Info.Initialization_Status = Init.Initialization_Legality_Indeterminate or else
        Info.Initialization_Status = Init.Initialization_Legality_Not_Checked
      then
         return Initialization_Object_Flow_Indeterminate;
      end if;

      if Expected /= Obj_Flow.Object_Flow_Unknown then
         if Info.Object_Flow_Row = Obj_Flow.No_Object_Flow_Row or else
           Info.Object_Flow_Matches = 0
         then
            return Initialization_Object_Flow_Missing_Object_Flow_Row;
         end if;

         if Info.Object_Flow_Kind /= Expected then
            return Initialization_Object_Flow_Mismatched_Object_Flow_Kind;
         end if;
      end if;

      if Obj_Flow.Has_Confident_Object_Flow
        ((Id => Info.Object_Flow_Row,
          Context => Info.Object_Flow_Row,
          Kind => Info.Object_Flow_Kind,
          Status => Info.Object_Flow_Status,
          Node => Info.Node,
          Object_Name => Info.Object_Name,
          Target_Type => Null_Unbounded_String,
          Source_Type => Null_Unbounded_String,
          Generic_Unit_Name => Null_Unbounded_String,
          Instance_Name => Null_Unbounded_String,
          Message => Null_Unbounded_String,
          Detail => Null_Unbounded_String,
          Accessibility_Row => Obj_Flow.Access_Consumers.No_Accessibility_Consumer_Row,
          Accessibility_Status => Obj_Flow.Access_Consumers.Accessibility_Consumer_Not_Checked,
          Accessibility_Kind => Obj_Flow.Access_Consumers.Accessibility_Consumer_Unknown,
          Accessibility_Matches => 0,
          Original_Object_Flow_Error => False,
          Start_Line => Info.Start_Line,
          Start_Column => Info.Start_Column,
          End_Line => Info.End_Line,
          End_Column => Info.End_Column,
          Source_Fingerprint => Info.Source_Fingerprint,
          Accessibility_Fingerprint => 0,
          Object_Flow_Fingerprint => Info.Object_Flow_Fingerprint,
          Fingerprint => 0))
      then
         return Legal_Status_For_Init (Info.Initialization_Status);
      end if;

      return Status_From_Object_Flow (Info.Object_Flow_Status);
   end Status_For;

   function Message_For (Status : Initialization_Object_Flow_Status) return String is
   begin
      case Status is
         when Initialization_Object_Flow_Legal_Definite_Init_Accepted |
              Initialization_Object_Flow_Legal_Default_Init_Accepted |
              Initialization_Object_Flow_Legal_Explicit_Init_Accepted |
              Initialization_Object_Flow_Legal_Component_Init_Accepted |
              Initialization_Object_Flow_Legal_Out_Parameter_Accepted |
              Initialization_Object_Flow_Legal_Return_Object_Accepted |
              Initialization_Object_Flow_Legal_Exception_Path_Accepted |
              Initialization_Object_Flow_Legal_Finalization_Path_Accepted =>
            return "definite-initialization flow accepted object-flow evidence";
         when Initialization_Object_Flow_Missing_Object_Flow_Row =>
            return "definite-initialization flow lacks object-flow evidence";
         when Initialization_Object_Flow_Mismatched_Object_Flow_Kind =>
            return "definite-initialization flow uses mismatched object-flow evidence";
         when Initialization_Object_Flow_Indeterminate =>
            return "definite-initialization object-flow consumer remains indeterminate";
         when others =>
            return "object-flow or initialization evidence blocks definite-initialization flow";
      end case;
   end Message_For;

   function Detail_For (Info : Initialization_Object_Flow_Info) return String is
   begin
      return "kind=" & Init.Initialization_Context_Kind'Image (Info.Kind) &
        ", initialization_status=" &
        Init.Initialization_Legality_Status'Image (Info.Initialization_Status) &
        ", object_flow_kind=" &
        Obj_Flow.Object_Flow_Context_Kind'Image (Info.Object_Flow_Kind) &
        ", object_flow_status=" &
        Obj_Flow.Object_Flow_Status'Image (Info.Object_Flow_Status);
   end Detail_For;

   function Make_Row
     (Info   : Initialization_Object_Flow_Context_Info;
      Status : Initialization_Object_Flow_Status)
      return Initialization_Object_Flow_Info is
      Row : Initialization_Object_Flow_Info;
   begin
      Row.Id := Info.Id;
      Row.Context := Info.Id;
      Row.Kind := Info.Kind;
      Row.Status := Status;
      Row.Node := Info.Node;
      Row.Object_Name := Info.Object_Name;
      Row.Initialization_Row := Info.Initialization_Row;
      Row.Initialization_Status := Info.Initialization_Status;
      Row.Before_State := Info.Before_State;
      Row.After_State := Info.After_State;
      Row.Flow := Info.Flow;
      Row.Object_Flow_Row := Info.Object_Flow_Row;
      Row.Object_Flow_Status := Info.Object_Flow_Status;
      Row.Object_Flow_Kind := Info.Object_Flow_Kind;
      Row.Object_Flow_Matches := Info.Object_Flow_Matches;
      Row.Start_Line := Info.Start_Line;
      Row.Start_Column := Info.Start_Column;
      Row.End_Line := Info.End_Line;
      Row.End_Column := Info.End_Column;
      Row.Source_Fingerprint := Info.Source_Fingerprint;
      Row.Initialization_Fingerprint := Info.Initialization_Fingerprint;
      Row.Object_Flow_Fingerprint := Info.Object_Flow_Fingerprint;
      Row.Message := To_Unbounded_String (Message_For (Status));
      Row.Fingerprint := Mix
        (Natural (Info.Id), Mix (Initialization_Object_Flow_Status'Pos (Status),
         Mix (Info.Source_Fingerprint, Mix (Info.Initialization_Fingerprint,
          Info.Object_Flow_Fingerprint))));
      Row.Detail := To_Unbounded_String (Detail_For (Row));
      return Row;
   end Make_Row;

   procedure Clear (Model : in out Initialization_Object_Flow_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Initialization_Object_Flow_Context_Model;
      Info  : Initialization_Object_Flow_Context_Info) is
   begin
      Model.Contexts.Append (Info);
      Model.Result_Fingerprint := Mix
        (Model.Result_Fingerprint,
         Mix (Natural (Info.Id), Mix (Info.Source_Fingerprint,
          Mix (Info.Initialization_Fingerprint, Info.Object_Flow_Fingerprint))));
   end Add_Context;

   function Context_Count (Model : Initialization_Object_Flow_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Initialization_Object_Flow_Context_Model;
      Index : Positive) return Initialization_Object_Flow_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Initialization_Object_Flow_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Build
     (Contexts : Initialization_Object_Flow_Context_Model)
      return Initialization_Object_Flow_Model is
      Result : Initialization_Object_Flow_Model;
      Row    : Initialization_Object_Flow_Info;
   begin
      for C of Contexts.Contexts loop
         Row := Make_Row (C, Status_For (C));
         Result.Rows.Append (Row);
         Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, Row.Fingerprint);
      end loop;
      return Result;
   end Build;

   function Row_Count (Model : Initialization_Object_Flow_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : Initialization_Object_Flow_Model;
      Index : Positive) return Initialization_Object_Flow_Info is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function First_For_Node
     (Model : Initialization_Object_Flow_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Initialization_Object_Flow_Info is
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Initialization_Object_Flow_Model;
      Status : Initialization_Object_Flow_Status) return Initialization_Object_Flow_Set is
      Result : Initialization_Object_Flow_Set;
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
     (Model : Initialization_Object_Flow_Model;
      Kind  : Init.Initialization_Context_Kind) return Initialization_Object_Flow_Set is
      Result : Initialization_Object_Flow_Set;
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
     (Model : Initialization_Object_Flow_Model;
      Name  : String) return Initialization_Object_Flow_Set is
      Result : Initialization_Object_Flow_Set;
   begin
      for Row of Model.Rows loop
         if Text (Row.Object_Name) = Name then
            Result.Items.Append (Row);
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Object;

   function Set_Count (Results : Initialization_Object_Flow_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Set_Count;

   function Set_At
     (Results : Initialization_Object_Flow_Set;
      Index   : Positive) return Initialization_Object_Flow_Info is
   begin
      return Results.Items.Element (Index);
   end Set_At;

   function Count_Status
     (Model  : Initialization_Object_Flow_Model;
      Status : Initialization_Object_Flow_Status) return Natural is
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
     (Model : Initialization_Object_Flow_Model;
      Kind  : Init.Initialization_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Has_Confident_Initialization_Flow
     (Info : Initialization_Object_Flow_Info) return Boolean is
   begin
      return Info.Status in Initialization_Object_Flow_Legal_Definite_Init_Accepted |
        Initialization_Object_Flow_Legal_Default_Init_Accepted |
        Initialization_Object_Flow_Legal_Explicit_Init_Accepted |
        Initialization_Object_Flow_Legal_Component_Init_Accepted |
        Initialization_Object_Flow_Legal_Out_Parameter_Accepted |
        Initialization_Object_Flow_Legal_Return_Object_Accepted |
        Initialization_Object_Flow_Legal_Exception_Path_Accepted |
        Initialization_Object_Flow_Legal_Finalization_Path_Accepted;
   end Has_Confident_Initialization_Flow;

   function Legal_Count (Model : Initialization_Object_Flow_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Has_Confident_Initialization_Flow (Row) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Legal_Count;

   function Is_Lifetime_Error (Status : Initialization_Object_Flow_Status) return Boolean is
   begin
      return Status in Initialization_Object_Flow_Return_Lifetime_Blocker |
        Initialization_Object_Flow_Allocator_Lifetime_Blocker |
        Initialization_Object_Flow_Access_Lifetime_Blocker |
        Initialization_Object_Flow_Generic_Lifetime_Blocker |
        Initialization_Object_Flow_Linked_Accessibility_Blocker;
   end Is_Lifetime_Error;

   function Is_Initialization_Error (Status : Initialization_Object_Flow_Status) return Boolean is
   begin
      return Status in Initialization_Object_Flow_Preserved_Read_Before_Write |
        Initialization_Object_Flow_Preserved_Component_Read_Before_Write |
        Initialization_Object_Flow_Preserved_Partial_Component_Init |
        Initialization_Object_Flow_Preserved_Out_Parameter_Not_Assigned |
        Initialization_Object_Flow_Preserved_In_Out_Conditional_Assignment |
        Initialization_Object_Flow_Preserved_Return_Object_Not_Initialized |
        Initialization_Object_Flow_Preserved_Branch_Merge_Not_Definite |
        Initialization_Object_Flow_Preserved_Loop_Merge_Not_Definite |
        Initialization_Object_Flow_Preserved_Exception_Path_Loss |
        Initialization_Object_Flow_Preserved_Finalization_Uses_Uninitialized |
        Initialization_Object_Flow_Preserved_Use_After_Finalization |
        Initialization_Object_Flow_Preserved_Linked_Initialization_Error;
   end Is_Initialization_Error;

   function Is_Representation_Error (Status : Initialization_Object_Flow_Status) return Boolean is
   begin
      return Status in Initialization_Object_Flow_Discriminant_Variant_Blocker |
        Initialization_Object_Flow_Representation_Blocker |
        Initialization_Object_Flow_Linked_Generic_Replay_Blocker;
   end Is_Representation_Error;

   function Is_Coverage_Error (Status : Initialization_Object_Flow_Status) return Boolean is
   begin
      return Status = Initialization_Object_Flow_Coverage_Blocker;
   end Is_Coverage_Error;

   function Error_Count (Model : Initialization_Object_Flow_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if not Has_Confident_Initialization_Flow (Row) and then
           Row.Status /= Initialization_Object_Flow_Indeterminate and then
           Row.Status /= Initialization_Object_Flow_Not_Checked
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Error_Count;

   function Lifetime_Error_Count (Model : Initialization_Object_Flow_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Lifetime_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Lifetime_Error_Count;

   function Initialization_Error_Count (Model : Initialization_Object_Flow_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Initialization_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Initialization_Error_Count;

   function Representation_Error_Count (Model : Initialization_Object_Flow_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Representation_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Representation_Error_Count;

   function Coverage_Error_Count (Model : Initialization_Object_Flow_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Coverage_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Coverage_Error_Count;

   function Indeterminate_Count (Model : Initialization_Object_Flow_Model) return Natural is
   begin
      return Count_Status (Model, Initialization_Object_Flow_Indeterminate);
   end Indeterminate_Count;

   function Fingerprint (Model : Initialization_Object_Flow_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Definite_Initialization_Object_Flow_Consumer_Legality;
