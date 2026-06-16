with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Tagged_Derived_Legality is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Tagged_Context_Id;
   use type Tagged_Legality_Id;
   use type Tagged_Legality_Status;
   use type Editor.Ada_Assignment_Legality.Assignment_Context_Id;
   use type Editor.Ada_Return_Legality.Return_Context_Id;
   use type Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Id;
   use type Editor.Ada_Assignment_Legality.Assignment_Legality_Status;
   use type Editor.Ada_Return_Legality.Return_Legality_Status;
   use type Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Status;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 281) + B + 227) mod 1_000_000_007;
   end Mix;

   function Bool_Slot (Value : Boolean) return Natural is
   begin
      if Value then
         return 2;
      else
         return 1;
      end if;
   end Bool_Slot;

   function Kind_Slot (Kind : Tagged_Context_Kind) return Natural is
   begin
      return Tagged_Context_Kind'Pos (Kind) + 1;
   end Kind_Slot;

   function Status_Slot (Status : Tagged_Legality_Status) return Natural is
   begin
      return Tagged_Legality_Status'Pos (Status) + 1;
   end Status_Slot;

   function Context_Fingerprint (Context : Tagged_Context_Info) return Natural is
      H : Natural := Natural (Context.Id) + 1;
   begin
      H := Mix (H, Kind_Slot (Context.Kind));
      H := Mix (H, Natural (Context.Node) + 1);
      H := Mix (H, Natural (Context.Type_Node) + 1);
      H := Mix (H, Natural (Context.Parent_Node) + 1);
      H := Mix (H, Natural (Context.Operation_Node) + 1);
      H := Mix (H, Natural (Context.Dispatch_Node) + 1);
      H := Mix (H, Length (Context.Normalized_Type_Name) + 1);
      H := Mix (H, Length (Context.Normalized_Parent_Name) + 1);
      H := Mix (H, Length (Context.Normalized_Operation_Name) + 1);
      H := Mix (H, Bool_Slot (Context.Parent_Resolved));
      H := Mix (H, Bool_Slot (Context.Parent_Is_Tagged));
      H := Mix (H, Bool_Slot (Context.Parent_Is_Limited));
      H := Mix (H, Bool_Slot (Context.Derived_Is_Limited));
      H := Mix (H, Bool_Slot (Context.Private_View_Barrier));
      H := Mix (H, Bool_Slot (Context.Limited_View_Barrier));
      H := Mix (H, Bool_Slot (Context.Interface_Operation_Present));
      H := Mix (H, Bool_Slot (Context.Interface_Profile_Matches));
      H := Mix (H, Bool_Slot (Context.Duplicate_Inherited_Primitive));
      H := Mix (H, Bool_Slot (Context.Requires_Overriding));
      H := Mix (H, Bool_Slot (Context.Overriding_Present));
      H := Mix (H, Bool_Slot (Context.Override_Is_Primitive));
      H := Mix (H, Bool_Slot (Context.Override_Profile_Matches));
      H := Mix (H, Bool_Slot (Context.Override_Mode_Matches));
      H := Mix (H, Bool_Slot (Context.Override_Result_Matches));
      H := Mix (H, Bool_Slot (Context.Type_Is_Abstract));
      H := Mix (H, Bool_Slot (Context.Operation_Is_Abstract));
      H := Mix (H, Bool_Slot (Context.Abstract_Operation_Overridden));
      H := Mix (H, Bool_Slot (Context.Controlling_Operand_Present));
      H := Mix (H, Bool_Slot (Context.Controlling_Result_Ambiguous));
      H := Mix (H, Bool_Slot (Context.Class_Wide_Conversion_Compatible));
      H := Mix (H, Natural (Context.Linked_Assignment) + 1);
      H := Mix (H, Natural (Context.Linked_Return) + 1);
      H := Mix (H, Natural (Context.Linked_Dispatch_Expression) + 1);
      H := Mix (H, Context.Start_Line);
      H := Mix (H, Context.Start_Column);
      H := Mix (H, Context.End_Line);
      H := Mix (H, Context.End_Column);
      return H;
   end Context_Fingerprint;

   function Legality_Fingerprint (Info : Tagged_Legality_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Kind_Slot (Info.Kind));
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Natural (Info.Type_Node) + 1);
      H := Mix (H, Natural (Info.Parent_Node) + 1);
      H := Mix (H, Natural (Info.Operation_Node) + 1);
      H := Mix (H, Natural (Info.Dispatch_Node) + 1);
      H := Mix (H, Status_Slot (Info.Status));
      H := Mix (H, Length (Info.Normalized_Type_Name) + 1);
      H := Mix (H, Length (Info.Normalized_Parent_Name) + 1);
      H := Mix (H, Length (Info.Normalized_Operation_Name) + 1);
      H := Mix (H, Natural (Info.Linked_Assignment) + 1);
      H := Mix (H, Natural (Info.Linked_Return) + 1);
      H := Mix (H, Natural (Info.Linked_Dispatch_Expression) + 1);
      H := Mix (H, Info.Start_Line);
      H := Mix (H, Info.Start_Column);
      H := Mix (H, Info.End_Line);
      H := Mix (H, Info.End_Column);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Legality_Fingerprint;

   function Is_Compatible_Status (Status : Tagged_Legality_Status) return Boolean is
   begin
      return Status in Tagged_Legality_Legal_Derivation |
        Tagged_Legality_Legal_Private_Extension |
        Tagged_Legality_Legal_Interface_Derivation |
        Tagged_Legality_Legal_Primitive_Operation |
        Tagged_Legality_Legal_Override |
        Tagged_Legality_Legal_Abstract_Type |
        Tagged_Legality_Legal_Dispatching_Call |
        Tagged_Legality_Legal_Class_Wide_Conversion;
   end Is_Compatible_Status;

   function Is_Error_Status (Status : Tagged_Legality_Status) return Boolean is
   begin
      return Status /= Tagged_Legality_Not_Checked
        and then Status /= Tagged_Legality_Indeterminate
        and then not Is_Compatible_Status (Status);
   end Is_Error_Status;

   function Is_Warning_Status (Status : Tagged_Legality_Status) return Boolean is
   begin
      return Status = Tagged_Legality_Indeterminate;
   end Is_Warning_Status;

   function Is_Parent_Error (Status : Tagged_Legality_Status) return Boolean is
   begin
      return Status in Tagged_Legality_Parent_Unresolved |
        Tagged_Legality_Parent_Not_Tagged |
        Tagged_Legality_Parent_Limited_Mismatch |
        Tagged_Legality_Private_View_Barrier |
        Tagged_Legality_Limited_View_Barrier;
   end Is_Parent_Error;

   function Is_Override_Error (Status : Tagged_Legality_Status) return Boolean is
   begin
      return Status in Tagged_Legality_Overriding_Missing |
        Tagged_Legality_Override_Not_Primitive |
        Tagged_Legality_Override_Profile_Mismatch |
        Tagged_Legality_Override_Mode_Mismatch |
        Tagged_Legality_Override_Result_Mismatch |
        Tagged_Legality_Duplicate_Inherited_Primitive;
   end Is_Override_Error;

   function Is_Interface_Error (Status : Tagged_Legality_Status) return Boolean is
   begin
      return Status in Tagged_Legality_Interface_Missing_Operation |
        Tagged_Legality_Interface_Profile_Mismatch;
   end Is_Interface_Error;

   function Is_Dispatching_Error (Status : Tagged_Legality_Status) return Boolean is
   begin
      return Status in Tagged_Legality_Dispatching_Target_Unresolved |
        Tagged_Legality_Dispatching_Target_Ambiguous |
        Tagged_Legality_Dispatching_Target_Not_Dispatching |
        Tagged_Legality_Controlling_Operand_Missing |
        Tagged_Legality_Controlling_Result_Ambiguous;
   end Is_Dispatching_Error;

   function Is_Abstract_Error (Status : Tagged_Legality_Status) return Boolean is
   begin
      return Status in Tagged_Legality_Abstract_Operation_Not_Overridden |
        Tagged_Legality_Nonabstract_Type_Has_Abstract_Operation;
   end Is_Abstract_Error;

   function Message_For (Status : Tagged_Legality_Status) return String is
   begin
      case Status is
         when Tagged_Legality_Legal_Derivation =>
            return "tagged derivation is legal";
         when Tagged_Legality_Legal_Private_Extension =>
            return "private extension is legal";
         when Tagged_Legality_Legal_Interface_Derivation =>
            return "interface derivation is legal";
         when Tagged_Legality_Legal_Primitive_Operation =>
            return "primitive operation inheritance is legal";
         when Tagged_Legality_Legal_Override =>
            return "overriding declaration is legal";
         when Tagged_Legality_Legal_Abstract_Type =>
            return "abstract type operation requirements are satisfied";
         when Tagged_Legality_Legal_Dispatching_Call =>
            return "dispatching call is legal";
         when Tagged_Legality_Legal_Class_Wide_Conversion =>
            return "class-wide conversion is legal";
         when Tagged_Legality_Parent_Unresolved =>
            return "tagged derivation parent type is unresolved";
         when Tagged_Legality_Parent_Not_Tagged =>
            return "derivation parent is not tagged";
         when Tagged_Legality_Parent_Limited_Mismatch =>
            return "limitedness of derived type does not match parent requirements";
         when Tagged_Legality_Private_View_Barrier =>
            return "tagged legality is blocked by a private view";
         when Tagged_Legality_Limited_View_Barrier =>
            return "tagged legality is blocked by a limited view";
         when Tagged_Legality_Interface_Missing_Operation =>
            return "interface operation is not implemented";
         when Tagged_Legality_Interface_Profile_Mismatch =>
            return "interface operation profile does not conform";
         when Tagged_Legality_Duplicate_Inherited_Primitive =>
            return "duplicate inherited primitive operation is unresolved";
         when Tagged_Legality_Overriding_Missing =>
            return "required overriding declaration is missing";
         when Tagged_Legality_Override_Not_Primitive =>
            return "overriding declaration does not denote a primitive operation";
         when Tagged_Legality_Override_Profile_Mismatch =>
            return "overriding profile does not conform";
         when Tagged_Legality_Override_Mode_Mismatch =>
            return "overriding parameter modes do not conform";
         when Tagged_Legality_Override_Result_Mismatch =>
            return "overriding result subtype does not conform";
         when Tagged_Legality_Abstract_Operation_Not_Overridden =>
            return "abstract operation is not overridden";
         when Tagged_Legality_Nonabstract_Type_Has_Abstract_Operation =>
            return "nonabstract tagged type has an abstract operation";
         when Tagged_Legality_Dispatching_Target_Unresolved =>
            return "dispatching target is unresolved";
         when Tagged_Legality_Dispatching_Target_Ambiguous =>
            return "dispatching target is ambiguous";
         when Tagged_Legality_Dispatching_Target_Not_Dispatching =>
            return "call target is not dispatching";
         when Tagged_Legality_Controlling_Operand_Missing =>
            return "dispatching call has no controlling operand";
         when Tagged_Legality_Controlling_Result_Ambiguous =>
            return "dispatching call has ambiguous controlling result";
         when Tagged_Legality_Class_Wide_Conversion_Incompatible =>
            return "class-wide conversion is incompatible";
         when Tagged_Legality_Assignment_Legality_Error =>
            return "linked assignment legality rejected this tagged context";
         when Tagged_Legality_Return_Legality_Error =>
            return "linked return legality rejected this tagged context";
         when Tagged_Legality_Indeterminate =>
            return "tagged/derived legality is indeterminate";
         when others =>
            return "tagged/derived legality was not checked";
      end case;
   end Message_For;

   function Detail_For (Status : Tagged_Legality_Status) return String is
   begin
      case Status is
         when Tagged_Legality_Assignment_Legality_Error =>
            return "assignment/object-initialization metadata must be legal before this tagged context can be accepted";
         when Tagged_Legality_Return_Legality_Error =>
            return "return-statement metadata must be legal before this tagged context can be accepted";
         when Tagged_Legality_Legal_Dispatching_Call =>
            return "dispatching metadata was resolved and accepted";
         when Tagged_Legality_Dispatching_Target_Not_Dispatching =>
            return "dispatching metadata resolved to a static or non-dispatching target where dispatching legality was required";
         when Tagged_Legality_Not_Checked =>
            return "no tagged/derived semantic context was available";
         when others =>
            return "classification derived from snapshot-owned tagged/derived semantic context";
      end case;
   end Detail_For;

   function Status_From_Dispatching
     (Context     : Tagged_Context_Info;
      Dispatching : Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Model)
      return Tagged_Legality_Status
   is
      Info : constant Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Info :=
        Editor.Ada_Dispatching_Call_Legality.First_For_Node
          (Dispatching, Context.Dispatch_Node);
      use type Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Id;
      use type Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Status;
   begin
      if not Context.Controlling_Operand_Present then
         return Tagged_Legality_Controlling_Operand_Missing;
      elsif Context.Controlling_Result_Ambiguous then
         return Tagged_Legality_Controlling_Result_Ambiguous;
      elsif Info.Id = Editor.Ada_Dispatching_Call_Legality.No_Dispatching_Legality then
         return Tagged_Legality_Dispatching_Target_Unresolved;
      end if;

      case Info.Status is
         when Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Dynamic_Dispatch |
              Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Controlling_Result |
              Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Primitive_Target =>
            return Tagged_Legality_Legal_Dispatching_Call;
         when Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Static_Binding |
              Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Not_Dispatching_Call =>
            return Tagged_Legality_Dispatching_Target_Not_Dispatching;
         when Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Target_Ambiguous =>
            return Tagged_Legality_Dispatching_Target_Ambiguous;
         when Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Target_Unresolved =>
            return Tagged_Legality_Dispatching_Target_Unresolved;
         when others =>
            return Tagged_Legality_Indeterminate;
      end case;
   end Status_From_Dispatching;

   function Has_Linked_Assignment_Error
     (Context     : Tagged_Context_Info;
      Assignments : Editor.Ada_Assignment_Legality.Assignment_Legality_Model)
      return Boolean
   is
      Info : constant Editor.Ada_Assignment_Legality.Assignment_Legality_Info :=
        Editor.Ada_Assignment_Legality.First_For_Context
          (Assignments, Context.Linked_Assignment);
   begin
      if Context.Linked_Assignment = Editor.Ada_Assignment_Legality.No_Assignment_Context then
         return False;
      end if;
      return Editor.Ada_Assignment_Legality.Has_Legality (Info)
        and then Editor.Ada_Assignment_Legality.Error_Count (Assignments) > 0
        and then Info.Status not in
          Editor.Ada_Assignment_Legality.Assignment_Legality_Compatible |
          Editor.Ada_Assignment_Legality.Assignment_Legality_Class_Wide_Compatible |
          Editor.Ada_Assignment_Legality.Assignment_Legality_Static_Range_Compatible;
   end Has_Linked_Assignment_Error;

   function Has_Linked_Return_Error
     (Context : Tagged_Context_Info;
      Returns : Editor.Ada_Return_Legality.Return_Legality_Model) return Boolean
   is
      Info : constant Editor.Ada_Return_Legality.Return_Legality_Info :=
        Editor.Ada_Return_Legality.First_For_Context (Returns, Context.Linked_Return);
   begin
      if Context.Linked_Return = Editor.Ada_Return_Legality.No_Return_Context then
         return False;
      end if;
      return Editor.Ada_Return_Legality.Has_Legality (Info)
        and then Info.Status not in
          Editor.Ada_Return_Legality.Return_Legality_Procedure_Return_Compatible |
          Editor.Ada_Return_Legality.Return_Legality_Function_Return_Compatible |
          Editor.Ada_Return_Legality.Return_Legality_Extended_Return_Compatible;
   end Has_Linked_Return_Error;

   function Classify
     (Context     : Tagged_Context_Info;
      Assignments : Editor.Ada_Assignment_Legality.Assignment_Legality_Model;
      Returns     : Editor.Ada_Return_Legality.Return_Legality_Model;
      Dispatching : Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Model)
      return Tagged_Legality_Status is
   begin
      if Context.Private_View_Barrier then
         return Tagged_Legality_Private_View_Barrier;
      elsif Context.Limited_View_Barrier then
         return Tagged_Legality_Limited_View_Barrier;
      elsif Has_Linked_Assignment_Error (Context, Assignments) then
         return Tagged_Legality_Assignment_Legality_Error;
      elsif Has_Linked_Return_Error (Context, Returns) then
         return Tagged_Legality_Return_Legality_Error;
      end if;

      case Context.Kind is
         when Tagged_Context_Type_Derivation |
              Tagged_Context_Private_Extension |
              Tagged_Context_Interface_Derivation =>
            if not Context.Parent_Resolved then
               return Tagged_Legality_Parent_Unresolved;
            elsif not Context.Parent_Is_Tagged then
               return Tagged_Legality_Parent_Not_Tagged;
            elsif Context.Parent_Is_Limited /= Context.Derived_Is_Limited then
               return Tagged_Legality_Parent_Limited_Mismatch;
            elsif Context.Kind = Tagged_Context_Private_Extension then
               return Tagged_Legality_Legal_Private_Extension;
            elsif Context.Kind = Tagged_Context_Interface_Derivation then
               if not Context.Interface_Operation_Present then
                  return Tagged_Legality_Interface_Missing_Operation;
               elsif not Context.Interface_Profile_Matches then
                  return Tagged_Legality_Interface_Profile_Mismatch;
               else
                  return Tagged_Legality_Legal_Interface_Derivation;
               end if;
            else
               return Tagged_Legality_Legal_Derivation;
            end if;

         when Tagged_Context_Primitive_Operation =>
            if Context.Duplicate_Inherited_Primitive then
               return Tagged_Legality_Duplicate_Inherited_Primitive;
            else
               return Tagged_Legality_Legal_Primitive_Operation;
            end if;

         when Tagged_Context_Overriding_Declaration =>
            if Context.Requires_Overriding and then not Context.Overriding_Present then
               return Tagged_Legality_Overriding_Missing;
            elsif not Context.Override_Is_Primitive then
               return Tagged_Legality_Override_Not_Primitive;
            elsif not Context.Override_Profile_Matches then
               return Tagged_Legality_Override_Profile_Mismatch;
            elsif not Context.Override_Mode_Matches then
               return Tagged_Legality_Override_Mode_Mismatch;
            elsif not Context.Override_Result_Matches then
               return Tagged_Legality_Override_Result_Mismatch;
            else
               return Tagged_Legality_Legal_Override;
            end if;

         when Tagged_Context_Abstract_Type |
              Tagged_Context_Interface_Operation =>
            if Context.Operation_Is_Abstract and then not Context.Abstract_Operation_Overridden then
               if Context.Type_Is_Abstract then
                  return Tagged_Legality_Abstract_Operation_Not_Overridden;
               else
                  return Tagged_Legality_Nonabstract_Type_Has_Abstract_Operation;
               end if;
            else
               return Tagged_Legality_Legal_Abstract_Type;
            end if;

         when Tagged_Context_Dispatching_Call =>
            return Status_From_Dispatching (Context, Dispatching);

         when Tagged_Context_Class_Wide_Conversion =>
            if Context.Class_Wide_Conversion_Compatible then
               return Tagged_Legality_Legal_Class_Wide_Conversion;
            else
               return Tagged_Legality_Class_Wide_Conversion_Incompatible;
            end if;

         when Tagged_Context_Unknown =>
            return Tagged_Legality_Indeterminate;
      end case;
   end Classify;

   procedure Add_Info
     (Model : in out Tagged_Legality_Model;
      Info  : Tagged_Legality_Info) is
   begin
      Model.Items.Append (Info);
      if Is_Compatible_Status (Info.Status) then
         Model.Compatible_Total := Model.Compatible_Total + 1;
      elsif Is_Error_Status (Info.Status) then
         Model.Error_Total := Model.Error_Total + 1;
      elsif Is_Warning_Status (Info.Status) then
         Model.Warning_Total := Model.Warning_Total + 1;
      else
         Model.Info_Total := Model.Info_Total + 1;
      end if;
      if Is_Parent_Error (Info.Status) then
         Model.Parent_Error_Total := Model.Parent_Error_Total + 1;
      end if;
      if Is_Override_Error (Info.Status) then
         Model.Override_Error_Total := Model.Override_Error_Total + 1;
      end if;
      if Is_Interface_Error (Info.Status) then
         Model.Interface_Error_Total := Model.Interface_Error_Total + 1;
      end if;
      if Is_Dispatching_Error (Info.Status) then
         Model.Dispatching_Error_Total := Model.Dispatching_Error_Total + 1;
      end if;
      if Is_Abstract_Error (Info.Status) then
         Model.Abstract_Error_Total := Model.Abstract_Error_Total + 1;
      end if;
      if Info.Status in Tagged_Legality_Assignment_Legality_Error |
        Tagged_Legality_Return_Legality_Error
      then
         Model.Linked_Semantic_Error_Total := Model.Linked_Semantic_Error_Total + 1;
      end if;
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Fingerprint + 1);
   end Add_Info;

   procedure Clear (Model : in out Tagged_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model   : in out Tagged_Context_Model;
      Context : Tagged_Context_Info)
   is
      Item : Tagged_Context_Info := Context;
   begin
      if Length (Item.Normalized_Type_Name) = 0 then
         Item.Normalized_Type_Name := Item.Type_Name;
      end if;
      if Length (Item.Normalized_Parent_Name) = 0 then
         Item.Normalized_Parent_Name := Item.Parent_Name;
      end if;
      if Length (Item.Normalized_Operation_Name) = 0 then
         Item.Normalized_Operation_Name := Item.Operation_Name;
      end if;
      if Item.Fingerprint = 0 then
         Item.Fingerprint := Context_Fingerprint (Item);
      end if;
      Model.Items.Append (Item);
      Model.Fingerprint := Mix (Model.Fingerprint, Item.Fingerprint + 1);
   end Add_Context;

   function Context_Count (Model : Tagged_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Context_At
     (Model : Tagged_Context_Model;
      Index : Positive) return Tagged_Context_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items.Element (Index);
   end Context_At;

   function Fingerprint (Model : Tagged_Context_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

   function Build
     (Contexts    : Tagged_Context_Model;
      Assignments : Editor.Ada_Assignment_Legality.Assignment_Legality_Model;
      Returns     : Editor.Ada_Return_Legality.Return_Legality_Model;
      Dispatching : Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Model)
      return Tagged_Legality_Model
   is
      Model : Tagged_Legality_Model;
      Next  : Tagged_Legality_Id := 1;
   begin
      for Context of Contexts.Items loop
         declare
            Info : Tagged_Legality_Info;
         begin
            Info.Id := Next;
            Next := Next + 1;
            Info.Context := Context.Id;
            Info.Kind := Context.Kind;
            Info.Node := Context.Node;
            Info.Type_Node := Context.Type_Node;
            Info.Parent_Node := Context.Parent_Node;
            Info.Operation_Node := Context.Operation_Node;
            Info.Dispatch_Node := Context.Dispatch_Node;
            Info.Normalized_Type_Name := Context.Normalized_Type_Name;
            Info.Normalized_Parent_Name := Context.Normalized_Parent_Name;
            Info.Normalized_Operation_Name := Context.Normalized_Operation_Name;
            Info.Linked_Assignment := Context.Linked_Assignment;
            Info.Linked_Return := Context.Linked_Return;
            Info.Linked_Dispatch_Expression := Context.Linked_Dispatch_Expression;
            Info.Start_Line := Context.Start_Line;
            Info.Start_Column := Context.Start_Column;
            Info.End_Line := Context.End_Line;
            Info.End_Column := Context.End_Column;
            Info.Source_Fingerprint := Context.Fingerprint;
            Info.Status := Classify (Context, Assignments, Returns, Dispatching);
            Info.Message := To_Unbounded_String (Message_For (Info.Status));
            Info.Detail := To_Unbounded_String (Detail_For (Info.Status));
            Info.Fingerprint := Legality_Fingerprint (Info);
            Add_Info (Model, Info);
         end;
      end loop;
      return Model;
   end Build;

   function Legality_Count (Model : Tagged_Legality_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Legality_Count;

   function Legality_At
     (Model : Tagged_Legality_Model;
      Index : Positive) return Tagged_Legality_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items.Element (Index);
   end Legality_At;

   function First_For_Context
     (Model   : Tagged_Legality_Model;
      Context : Tagged_Context_Id) return Tagged_Legality_Info is
   begin
      for Info of Model.Items loop
         if Info.Context = Context then
            return Info;
         end if;
      end loop;
      return (others => <>);
   end First_For_Context;

   function First_For_Node
     (Model : Tagged_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Tagged_Legality_Info is
   begin
      for Info of Model.Items loop
         if Info.Node = Node or else Info.Type_Node = Node
           or else Info.Parent_Node = Node or else Info.Operation_Node = Node
           or else Info.Dispatch_Node = Node
         then
            return Info;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Tagged_Legality_Model;
      Status : Tagged_Legality_Status) return Tagged_Result_Set
   is
      Results : Tagged_Result_Set;
   begin
      for Info of Model.Items loop
         if Info.Status = Status then
            Results.Items.Append (Info);
            Results.Fingerprint := Mix (Results.Fingerprint, Info.Fingerprint + 1);
         end if;
      end loop;
      return Results;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Tagged_Legality_Model;
      Kind  : Tagged_Context_Kind) return Tagged_Result_Set
   is
      Results : Tagged_Result_Set;
   begin
      for Info of Model.Items loop
         if Info.Kind = Kind then
            Results.Items.Append (Info);
            Results.Fingerprint := Mix (Results.Fingerprint, Info.Fingerprint + 1);
         end if;
      end loop;
      return Results;
   end Rows_For_Kind;

   function Rows_For_Type
     (Model : Tagged_Legality_Model;
      Name  : Ada.Strings.Unbounded.Unbounded_String) return Tagged_Result_Set
   is
      Results : Tagged_Result_Set;
   begin
      for Info of Model.Items loop
         if Info.Normalized_Type_Name = Name then
            Results.Items.Append (Info);
            Results.Fingerprint := Mix (Results.Fingerprint, Info.Fingerprint + 1);
         end if;
      end loop;
      return Results;
   end Rows_For_Type;

   function Rows_For_Operation
     (Model : Tagged_Legality_Model;
      Name  : Ada.Strings.Unbounded.Unbounded_String) return Tagged_Result_Set
   is
      Results : Tagged_Result_Set;
   begin
      for Info of Model.Items loop
         if Info.Normalized_Operation_Name = Name then
            Results.Items.Append (Info);
            Results.Fingerprint := Mix (Results.Fingerprint, Info.Fingerprint + 1);
         end if;
      end loop;
      return Results;
   end Rows_For_Operation;

   function Result_Count (Results : Tagged_Result_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Result_Count;

   function Result_At
     (Results : Tagged_Result_Set;
      Index   : Positive) return Tagged_Legality_Info is
   begin
      if Index > Natural (Results.Items.Length) then
         return (others => <>);
      end if;
      return Results.Items.Element (Index);
   end Result_At;

   function Count_Status
     (Model  : Tagged_Legality_Model;
      Status : Tagged_Legality_Status) return Natural
   is
      Total : Natural := 0;
   begin
      for Info of Model.Items loop
         if Info.Status = Status then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Count_Status;

   function Count_Kind
     (Model : Tagged_Legality_Model;
      Kind  : Tagged_Context_Kind) return Natural
   is
      Total : Natural := 0;
   begin
      for Info of Model.Items loop
         if Info.Kind = Kind then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Count_Kind;

   function Compatible_Count (Model : Tagged_Legality_Model) return Natural is
   begin
      return Model.Compatible_Total;
   end Compatible_Count;

   function Error_Count (Model : Tagged_Legality_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Warning_Count (Model : Tagged_Legality_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Count;

   function Info_Count (Model : Tagged_Legality_Model) return Natural is
   begin
      return Model.Info_Total;
   end Info_Count;

   function Parent_Error_Count (Model : Tagged_Legality_Model) return Natural is
   begin
      return Model.Parent_Error_Total;
   end Parent_Error_Count;

   function Override_Error_Count (Model : Tagged_Legality_Model) return Natural is
   begin
      return Model.Override_Error_Total;
   end Override_Error_Count;

   function Interface_Error_Count (Model : Tagged_Legality_Model) return Natural is
   begin
      return Model.Interface_Error_Total;
   end Interface_Error_Count;

   function Dispatching_Error_Count (Model : Tagged_Legality_Model) return Natural is
   begin
      return Model.Dispatching_Error_Total;
   end Dispatching_Error_Count;

   function Abstract_Error_Count (Model : Tagged_Legality_Model) return Natural is
   begin
      return Model.Abstract_Error_Total;
   end Abstract_Error_Count;

   function Linked_Semantic_Error_Count (Model : Tagged_Legality_Model) return Natural is
   begin
      return Model.Linked_Semantic_Error_Total;
   end Linked_Semantic_Error_Count;

   function Has_Legality (Info : Tagged_Legality_Info) return Boolean is
   begin
      return Info.Id /= No_Tagged_Legality;
   end Has_Legality;

   function Fingerprint (Model : Tagged_Legality_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Tagged_Derived_Legality;
