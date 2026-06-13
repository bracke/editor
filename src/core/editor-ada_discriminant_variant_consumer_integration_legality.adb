with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Discriminant_Variant_Consumer_Integration_Legality is


   use type Disc_AST.Discriminant_Variant_AST_Repair_Status;
   use type Rep_CPD.Representation_Tasking_CPD_Status;
   use type Backmap.Generic_Backmap_Status;
   use type Disc_Generic.Discriminant_Generic_Row_Id;
   use type Disc_AST.Discriminant_Variant_AST_Repair_Row_Id;
   use type Rep_CPD.Representation_Tasking_CPD_Row_Id;
   use type Backmap.Generic_Backmap_Row_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   function Mix (Left, Right : Natural) return Natural is
      type Hash_Value is mod 2 ** 32;
      Mixed : constant Hash_Value :=
        Hash_Value (Left) * 16#01000193# + Hash_Value (Right) + 16#9E3779B9#;
   begin
      return Natural (Mixed mod Hash_Value (2_147_483_647));
   end Mix;

   function Text_Hash (Text : Unbounded_String) return Natural is
      S : constant String := To_String (Text);
      H : Natural := 2166136261 mod Natural'Last;
   begin
      for C of S loop
         H := Mix (H, Character'Pos (C) + 1);
      end loop;
      return H;
   end Text_Hash;

   function Is_Legal (Status : Discriminant_Consumer_Status) return Boolean is
   begin
      case Status is
         when Discriminant_Consumer_Legal_Record_Layout_Accepted |
              Discriminant_Consumer_Legal_Record_Aggregate_Accepted |
              Discriminant_Consumer_Legal_Extension_Aggregate_Accepted |
              Discriminant_Consumer_Legal_Assignment_Accepted |
              Discriminant_Consumer_Legal_Conversion_Accepted |
              Discriminant_Consumer_Legal_Return_Accepted |
              Discriminant_Consumer_Legal_Allocator_Accepted |
              Discriminant_Consumer_Legal_Access_Discriminant_Accepted |
              Discriminant_Consumer_Legal_Freezing_Effect_Accepted |
              Discriminant_Consumer_Legal_Representation_Clause_Accepted |
              Discriminant_Consumer_Legal_Generic_Replay_Accepted |
              Discriminant_Consumer_Legal_Private_Full_View_Accepted =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Legal;

   function Is_Discriminant_Error (Status : Discriminant_Consumer_Status) return Boolean is
   begin
      return Status in Discriminant_Consumer_Missing_Discriminant_Generic_Row |
                       Discriminant_Consumer_Discriminant_Generic_Blocker |
                       Discriminant_Consumer_Record_Layout_Discriminant_Blocker |
                       Discriminant_Consumer_Aggregate_Discriminant_Blocker |
                       Discriminant_Consumer_Access_Discriminant_Lifetime_Blocker |
                       Discriminant_Consumer_Private_Full_View_Mismatch_Blocker |
                       Discriminant_Consumer_Variant_Coverage_Blocker |
                       Discriminant_Consumer_Freezing_Discriminant_Blocker |
                       Discriminant_Consumer_Generic_Replay_Discriminant_Blocker |
                       Discriminant_Consumer_Multiple_Discriminant_Generic_Blockers;
   end Is_Discriminant_Error;

   function Is_AST_Repair_Error (Status : Discriminant_Consumer_Status) return Boolean is
   begin
      return Status in Discriminant_Consumer_Missing_AST_Repair_Row |
                       Discriminant_Consumer_AST_Repair_Blocker |
                       Discriminant_Consumer_Multiple_AST_Repair_Blockers;
   end Is_AST_Repair_Error;

   function Is_Representation_Error (Status : Discriminant_Consumer_Status) return Boolean is
   begin
      return Status in Discriminant_Consumer_Missing_Representation_CPD_Row |
                       Discriminant_Consumer_Representation_CPD_Blocker |
                       Discriminant_Consumer_Multiple_Representation_CPD_Blockers |
                       Discriminant_Consumer_Freezing_Discriminant_Blocker;
   end Is_Representation_Error;

   function Is_Generic_Backmap_Error (Status : Discriminant_Consumer_Status) return Boolean is
   begin
      return Status in Discriminant_Consumer_Missing_Generic_Backmap_Row |
                       Discriminant_Consumer_Generic_Backmap_Blocker |
                       Discriminant_Consumer_Generic_Replay_Discriminant_Blocker |
                       Discriminant_Consumer_Multiple_Generic_Backmap_Blockers;
   end Is_Generic_Backmap_Error;

   function Is_Indeterminate (Status : Discriminant_Consumer_Status) return Boolean is
   begin
      return Status in Discriminant_Consumer_Discriminant_Generic_Indeterminate |
                       Discriminant_Consumer_AST_Repair_Indeterminate |
                       Discriminant_Consumer_Representation_CPD_Indeterminate |
                       Discriminant_Consumer_Generic_Backmap_Indeterminate |
                       Discriminant_Consumer_Indeterminate;
   end Is_Indeterminate;

   function Legal_Status_For_Kind
     (Kind : Discriminant_Consumer_Context_Kind) return Discriminant_Consumer_Status is
   begin
      case Kind is
         when Discriminant_Consumer_Record_Layout =>
            return Discriminant_Consumer_Legal_Record_Layout_Accepted;
         when Discriminant_Consumer_Record_Aggregate =>
            return Discriminant_Consumer_Legal_Record_Aggregate_Accepted;
         when Discriminant_Consumer_Extension_Aggregate =>
            return Discriminant_Consumer_Legal_Extension_Aggregate_Accepted;
         when Discriminant_Consumer_Assignment =>
            return Discriminant_Consumer_Legal_Assignment_Accepted;
         when Discriminant_Consumer_Conversion =>
            return Discriminant_Consumer_Legal_Conversion_Accepted;
         when Discriminant_Consumer_Return =>
            return Discriminant_Consumer_Legal_Return_Accepted;
         when Discriminant_Consumer_Allocator =>
            return Discriminant_Consumer_Legal_Allocator_Accepted;
         when Discriminant_Consumer_Access_Discriminant =>
            return Discriminant_Consumer_Legal_Access_Discriminant_Accepted;
         when Discriminant_Consumer_Freezing_Effect =>
            return Discriminant_Consumer_Legal_Freezing_Effect_Accepted;
         when Discriminant_Consumer_Representation_Clause =>
            return Discriminant_Consumer_Legal_Representation_Clause_Accepted;
         when Discriminant_Consumer_Generic_Replay =>
            return Discriminant_Consumer_Legal_Generic_Replay_Accepted;
         when Discriminant_Consumer_Private_Full_View =>
            return Discriminant_Consumer_Legal_Private_Full_View_Accepted;
         when others =>
            return Discriminant_Consumer_Indeterminate;
      end case;
   end Legal_Status_For_Kind;

   function Status_From_Discriminant_Generic
     (Status : Disc_Generic.Discriminant_Generic_Status;
      Kind   : Discriminant_Consumer_Context_Kind) return Discriminant_Consumer_Status is
   begin
      if Disc_Generic.Is_Legal (Status) then
         return Discriminant_Consumer_Not_Checked;
      end if;

      case Status is
         when Disc_Generic.Discriminant_Generic_Not_Checked |
              Disc_Generic.Discriminant_Generic_Indeterminate =>
            return Discriminant_Consumer_Discriminant_Generic_Indeterminate;
         when Disc_Generic.Discriminant_Generic_Variant_Missing_For_Value |
              Disc_Generic.Discriminant_Generic_Variant_Forbidden_For_Value |
              Disc_Generic.Discriminant_Generic_Variant_Choice_Overlap |
              Disc_Generic.Discriminant_Generic_Variant_Choice_Coverage_Gap =>
            return Discriminant_Consumer_Variant_Coverage_Blocker;
         when Disc_Generic.Discriminant_Generic_Private_Full_View_Mismatch =>
            return Discriminant_Consumer_Private_Full_View_Mismatch_Blocker;
         when Disc_Generic.Discriminant_Generic_Linked_Generic_Replay_Error |
              Disc_Generic.Discriminant_Generic_Generic_Replay_Error =>
            return Discriminant_Consumer_Generic_Replay_Discriminant_Blocker;
         when Disc_Generic.Discriminant_Generic_Generic_Representation_Error |
              Disc_Generic.Discriminant_Generic_Representation_Flow_Tasking_Error |
              Disc_Generic.Discriminant_Generic_Representation_Flow_Global_Error |
              Disc_Generic.Discriminant_Generic_Representation_Flow_Depends_Error |
              Disc_Generic.Discriminant_Generic_Representation_Flow_Propagation_Error =>
            return Discriminant_Consumer_Freezing_Discriminant_Blocker;
         when others =>
            case Kind is
               when Discriminant_Consumer_Record_Layout =>
                  return Discriminant_Consumer_Record_Layout_Discriminant_Blocker;
               when Discriminant_Consumer_Record_Aggregate |
                    Discriminant_Consumer_Extension_Aggregate =>
                  return Discriminant_Consumer_Aggregate_Discriminant_Blocker;
               when Discriminant_Consumer_Access_Discriminant =>
                  return Discriminant_Consumer_Access_Discriminant_Lifetime_Blocker;
               when Discriminant_Consumer_Freezing_Effect |
                    Discriminant_Consumer_Representation_Clause =>
                  return Discriminant_Consumer_Freezing_Discriminant_Blocker;
               when Discriminant_Consumer_Generic_Replay =>
                  return Discriminant_Consumer_Generic_Replay_Discriminant_Blocker;
               when Discriminant_Consumer_Private_Full_View =>
                  return Discriminant_Consumer_Private_Full_View_Mismatch_Blocker;
               when others =>
                  return Discriminant_Consumer_Discriminant_Generic_Blocker;
            end case;
      end case;
   end Status_From_Discriminant_Generic;

   function Status_From_AST
     (Status : Disc_AST.Discriminant_Variant_AST_Repair_Status) return Discriminant_Consumer_Status is
   begin
      if Disc_AST.Is_Accepted (Status) then
         return Discriminant_Consumer_Not_Checked;
      elsif Status = Disc_AST.Discriminant_Variant_AST_Not_Checked or else
        Status = Disc_AST.Discriminant_Variant_AST_Indeterminate
      then
         return Discriminant_Consumer_AST_Repair_Indeterminate;
      else
         return Discriminant_Consumer_AST_Repair_Blocker;
      end if;
   end Status_From_AST;

   function Status_From_Representation
     (Status : Rep_CPD.Representation_Tasking_CPD_Status) return Discriminant_Consumer_Status is
   begin
      if Rep_CPD.Is_Legal (Status) then
         return Discriminant_Consumer_Not_Checked;
      elsif Status = Rep_CPD.Representation_Tasking_CPD_Not_Checked or else
        Status = Rep_CPD.Representation_Tasking_CPD_Tasking_CPD_Indeterminate or else
        Status = Rep_CPD.Representation_Tasking_CPD_Indeterminate
      then
         return Discriminant_Consumer_Representation_CPD_Indeterminate;
      else
         return Discriminant_Consumer_Representation_CPD_Blocker;
      end if;
   end Status_From_Representation;

   function Status_From_Backmap
     (Status : Backmap.Generic_Backmap_Status) return Discriminant_Consumer_Status is
   begin
      if Backmap.Is_Legal (Status) then
         return Discriminant_Consumer_Not_Checked;
      elsif Status = Backmap.Generic_Backmap_Not_Checked or else
        Status = Backmap.Generic_Backmap_Indeterminate or else
        Status = Backmap.Generic_Backmap_Replay_CPD_Indeterminate or else
        Status = Backmap.Generic_Backmap_Overload_Type_Edge_Indeterminate
      then
         return Discriminant_Consumer_Generic_Backmap_Indeterminate;
      else
         return Discriminant_Consumer_Generic_Backmap_Blocker;
      end if;
   end Status_From_Backmap;

   function Status_For (Info : Discriminant_Consumer_Context_Info) return Discriminant_Consumer_Status is
      Candidate : Discriminant_Consumer_Status;
   begin
      if Info.Disc_Generic_Matches > 1 then
         return Discriminant_Consumer_Multiple_Discriminant_Generic_Blockers;
      elsif Info.Disc_Generic_Row = Disc_Generic.No_Discriminant_Generic_Row then
         return Discriminant_Consumer_Missing_Discriminant_Generic_Row;
      end if;

      Candidate := Status_From_Discriminant_Generic (Info.Disc_Generic_Status, Info.Kind);
      if Candidate /= Discriminant_Consumer_Not_Checked then
         return Candidate;
      end if;

      if Info.Requires_AST_Repair then
         if Info.AST_Repair_Matches > 1 then
            return Discriminant_Consumer_Multiple_AST_Repair_Blockers;
         elsif Info.AST_Repair_Row = Disc_AST.No_Discriminant_Variant_AST_Repair_Row then
            return Discriminant_Consumer_Missing_AST_Repair_Row;
         end if;

         Candidate := Status_From_AST (Info.AST_Repair_Status);
         if Candidate /= Discriminant_Consumer_Not_Checked then
            return Candidate;
         end if;
      end if;

      if Info.Requires_Representation_CPD then
         if Info.Representation_CPD_Matches > 1 then
            return Discriminant_Consumer_Multiple_Representation_CPD_Blockers;
         elsif Info.Representation_CPD_Row = Rep_CPD.No_Representation_Tasking_CPD_Row then
            return Discriminant_Consumer_Missing_Representation_CPD_Row;
         end if;

         Candidate := Status_From_Representation (Info.Representation_CPD_Status);
         if Candidate /= Discriminant_Consumer_Not_Checked then
            return Candidate;
         end if;
      end if;

      if Info.Requires_Generic_Backmap then
         if Info.Generic_Backmap_Matches > 1 then
            return Discriminant_Consumer_Multiple_Generic_Backmap_Blockers;
         elsif Info.Generic_Backmap_Row = Backmap.No_Generic_Backmap_Row then
            return Discriminant_Consumer_Missing_Generic_Backmap_Row;
         end if;

         Candidate := Status_From_Backmap (Info.Generic_Backmap_Status);
         if Candidate /= Discriminant_Consumer_Not_Checked then
            return Candidate;
         end if;
      end if;

      return Legal_Status_For_Kind (Info.Kind);
   end Status_For;

   function Row_Fingerprint (Info : Discriminant_Consumer_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Discriminant_Consumer_Context_Kind'Pos (Info.Kind) + 1);
      H := Mix (H, Discriminant_Consumer_Status'Pos (Info.Status) + 1);
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Natural (Info.Type_Node) + 1);
      H := Mix (H, Natural (Info.Discriminant_Node) + 1);
      H := Mix (H, Natural (Info.Variant_Node) + 1);
      H := Mix (H, Natural (Info.Consumer_Node) + 1);
      H := Mix (H, Text_Hash (Info.Type_Name));
      H := Mix (H, Text_Hash (Info.Object_Name));
      H := Mix (H, Text_Hash (Info.Unit_Name));
      H := Mix (H, Text_Hash (Info.Instance_Name));
      H := Mix (H, Natural (Info.Disc_Generic_Row) + 1);
      H := Mix (H, Disc_Generic.Discriminant_Generic_Status'Pos (Info.Disc_Generic_Status) + 1);
      H := Mix (H, Natural (Info.AST_Repair_Row) + 1);
      H := Mix (H, Disc_AST.Discriminant_Variant_AST_Repair_Status'Pos (Info.AST_Repair_Status) + 1);
      H := Mix (H, Natural (Info.Representation_CPD_Row) + 1);
      H := Mix (H, Rep_CPD.Representation_Tasking_CPD_Status'Pos (Info.Representation_CPD_Status) + 1);
      H := Mix (H, Natural (Info.Generic_Backmap_Row) + 1);
      H := Mix (H, Backmap.Generic_Backmap_Status'Pos (Info.Generic_Backmap_Status) + 1);
      H := Mix (H, Info.Source_Fingerprint + 1);
      H := Mix (H, Info.Consumer_Fingerprint + 1);
      return H;
   end Row_Fingerprint;

   function Message_For (Status : Discriminant_Consumer_Status) return Unbounded_String is
   begin
      case Status is
         when Discriminant_Consumer_Missing_Discriminant_Generic_Row =>
            return To_Unbounded_String ("missing discriminant/variant semantic evidence for downstream consumer");
         when Discriminant_Consumer_Discriminant_Generic_Blocker =>
            return To_Unbounded_String ("discriminant/variant legality blocks downstream consumer");
         when Discriminant_Consumer_Record_Layout_Discriminant_Blocker =>
            return To_Unbounded_String ("record layout cannot ignore discriminant/variant blocker");
         when Discriminant_Consumer_Aggregate_Discriminant_Blocker =>
            return To_Unbounded_String ("aggregate legality cannot ignore discriminant/variant blocker");
         when Discriminant_Consumer_Access_Discriminant_Lifetime_Blocker =>
            return To_Unbounded_String ("access discriminant consumer lacks accepted lifetime-safe discriminant evidence");
         when Discriminant_Consumer_Private_Full_View_Mismatch_Blocker =>
            return To_Unbounded_String ("private/full-view discriminant mismatch blocks consumer");
         when Discriminant_Consumer_Variant_Coverage_Blocker =>
            return To_Unbounded_String ("variant coverage blocker prevents confident consumer legality");
         when Discriminant_Consumer_Freezing_Discriminant_Blocker =>
            return To_Unbounded_String ("representation/freezing consumer lacks accepted discriminant evidence");
         when Discriminant_Consumer_Generic_Replay_Discriminant_Blocker =>
            return To_Unbounded_String ("generic replay consumer lacks accepted discriminant backmapping evidence");
         when Discriminant_Consumer_Missing_AST_Repair_Row =>
            return To_Unbounded_String ("missing repaired discriminant/variant AST evidence");
         when Discriminant_Consumer_AST_Repair_Blocker =>
            return To_Unbounded_String ("unrepaired discriminant/variant AST coverage blocks consumer");
         when Discriminant_Consumer_Missing_Representation_CPD_Row =>
            return To_Unbounded_String ("missing representation/freezing CPD evidence for discriminant consumer");
         when Discriminant_Consumer_Representation_CPD_Blocker =>
            return To_Unbounded_String ("representation/freezing CPD evidence blocks discriminant consumer");
         when Discriminant_Consumer_Missing_Generic_Backmap_Row =>
            return To_Unbounded_String ("missing generic replay source/instance backmap for discriminant consumer");
         when Discriminant_Consumer_Generic_Backmap_Blocker =>
            return To_Unbounded_String ("generic replay source/instance backmap blocks discriminant consumer");
         when Discriminant_Consumer_Multiple_Discriminant_Generic_Blockers |
              Discriminant_Consumer_Multiple_AST_Repair_Blockers |
              Discriminant_Consumer_Multiple_Representation_CPD_Blockers |
              Discriminant_Consumer_Multiple_Generic_Backmap_Blockers =>
            return To_Unbounded_String ("multiple matching discriminant consumer blockers prevent confident legality");
         when Discriminant_Consumer_Discriminant_Generic_Indeterminate |
              Discriminant_Consumer_AST_Repair_Indeterminate |
              Discriminant_Consumer_Representation_CPD_Indeterminate |
              Discriminant_Consumer_Generic_Backmap_Indeterminate |
              Discriminant_Consumer_Indeterminate =>
            return To_Unbounded_String ("discriminant/variant consumer integration is indeterminate");
         when others =>
            return To_Unbounded_String ("discriminant/variant consumer integration accepted");
      end case;
   end Message_For;

   procedure Clear (Model : in out Discriminant_Consumer_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Discriminant_Consumer_Context_Model;
      Info  : Discriminant_Consumer_Context_Info) is
   begin
      Model.Contexts.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id) + Info.Source_Fingerprint + Info.Consumer_Fingerprint + 1);
   end Add_Context;

   function Context_Count (Model : Discriminant_Consumer_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Discriminant_Consumer_Context_Model;
      Index : Positive) return Discriminant_Consumer_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Discriminant_Consumer_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Build (Contexts : Discriminant_Consumer_Context_Model) return Discriminant_Consumer_Model is
      Model : Discriminant_Consumer_Model;
      Row   : Discriminant_Consumer_Info;
   begin
      for I in 1 .. Natural (Contexts.Contexts.Length) loop
         declare
            C : constant Discriminant_Consumer_Context_Info := Contexts.Contexts.Element (I);
         begin
            Row := (others => <>);
            Row.Id := Discriminant_Consumer_Row_Id (I);
            Row.Context := C.Id;
            Row.Kind := C.Kind;
            Row.Status := Status_For (C);
            Row.Node := C.Node;
            Row.Type_Node := C.Type_Node;
            Row.Discriminant_Node := C.Discriminant_Node;
            Row.Variant_Node := C.Variant_Node;
            Row.Consumer_Node := C.Consumer_Node;
            Row.Type_Name := C.Type_Name;
            Row.Object_Name := C.Object_Name;
            Row.Unit_Name := C.Unit_Name;
            Row.Instance_Name := C.Instance_Name;
            Row.Message := Message_For (Row.Status);
            Row.Detail := To_Unbounded_String (Discriminant_Consumer_Context_Kind'Image (C.Kind));
            Row.Disc_Generic_Row := C.Disc_Generic_Row;
            Row.Disc_Generic_Status := C.Disc_Generic_Status;
            Row.AST_Repair_Row := C.AST_Repair_Row;
            Row.AST_Repair_Status := C.AST_Repair_Status;
            Row.Representation_CPD_Row := C.Representation_CPD_Row;
            Row.Representation_CPD_Status := C.Representation_CPD_Status;
            Row.Generic_Backmap_Row := C.Generic_Backmap_Row;
            Row.Generic_Backmap_Status := C.Generic_Backmap_Status;
            Row.Source_Fingerprint := C.Source_Fingerprint;
            Row.Consumer_Fingerprint := C.Consumer_Fingerprint;
            Row.Fingerprint := Row_Fingerprint (Row);

            if Is_Legal (Row.Status) then
               Model.Legal_Total := Model.Legal_Total + 1;
            elsif Is_Indeterminate (Row.Status) then
               Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
            else
               Model.Error_Total := Model.Error_Total + 1;
            end if;

            if Is_Discriminant_Error (Row.Status) then
               Model.Discriminant_Error_Total := Model.Discriminant_Error_Total + 1;
            end if;
            if Is_AST_Repair_Error (Row.Status) then
               Model.AST_Repair_Error_Total := Model.AST_Repair_Error_Total + 1;
            end if;
            if Is_Representation_Error (Row.Status) then
               Model.Representation_Error_Total := Model.Representation_Error_Total + 1;
            end if;
            if Is_Generic_Backmap_Error (Row.Status) then
               Model.Generic_Backmap_Error_Total := Model.Generic_Backmap_Error_Total + 1;
            end if;

            Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Row.Fingerprint);
            Model.Items.Append (Row);
         end;
      end loop;
      return Model;
   end Build;

   function Row_Count (Model : Discriminant_Consumer_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Row_Count;

   function Row_At
     (Model : Discriminant_Consumer_Model;
      Index : Positive) return Discriminant_Consumer_Info is
   begin
      return Model.Items.Element (Index);
   end Row_At;

   function First_For_Node
     (Model : Discriminant_Consumer_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Discriminant_Consumer_Info is
   begin
      for Row of Model.Items loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Discriminant_Consumer_Model;
      Status : Discriminant_Consumer_Status) return Discriminant_Consumer_Set is
      Set : Discriminant_Consumer_Set;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then
            Set.Items.Append (Row);
            Set.Result_Fingerprint := Mix (Set.Result_Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Set;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Discriminant_Consumer_Model;
      Kind  : Discriminant_Consumer_Context_Kind) return Discriminant_Consumer_Set is
      Set : Discriminant_Consumer_Set;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then
            Set.Items.Append (Row);
            Set.Result_Fingerprint := Mix (Set.Result_Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Set;
   end Rows_For_Kind;

   function Rows_For_Type
     (Model : Discriminant_Consumer_Model;
      Name  : String) return Discriminant_Consumer_Set is
      Set : Discriminant_Consumer_Set;
   begin
      for Row of Model.Items loop
         if To_String (Row.Type_Name) = Name then
            Set.Items.Append (Row);
            Set.Result_Fingerprint := Mix (Set.Result_Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Set;
   end Rows_For_Type;

   function Set_Count (Set : Discriminant_Consumer_Set) return Natural is
   begin
      return Natural (Set.Items.Length);
   end Set_Count;

   function Set_At
     (Set   : Discriminant_Consumer_Set;
      Index : Positive) return Discriminant_Consumer_Info is
   begin
      return Set.Items.Element (Index);
   end Set_At;

   function Count_Status
     (Model  : Discriminant_Consumer_Model;
      Status : Discriminant_Consumer_Status) return Natural is
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
     (Model : Discriminant_Consumer_Model;
      Kind  : Discriminant_Consumer_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : Discriminant_Consumer_Model) return Natural is
   begin
      return Model.Legal_Total;
   end Legal_Count;

   function Error_Count (Model : Discriminant_Consumer_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Discriminant_Error_Count (Model : Discriminant_Consumer_Model) return Natural is
   begin
      return Model.Discriminant_Error_Total;
   end Discriminant_Error_Count;

   function AST_Repair_Error_Count (Model : Discriminant_Consumer_Model) return Natural is
   begin
      return Model.AST_Repair_Error_Total;
   end AST_Repair_Error_Count;

   function Representation_Error_Count (Model : Discriminant_Consumer_Model) return Natural is
   begin
      return Model.Representation_Error_Total;
   end Representation_Error_Count;

   function Generic_Backmap_Error_Count (Model : Discriminant_Consumer_Model) return Natural is
   begin
      return Model.Generic_Backmap_Error_Total;
   end Generic_Backmap_Error_Count;

   function Indeterminate_Count (Model : Discriminant_Consumer_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Discriminant_Consumer_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Discriminant_Variant_Consumer_Integration_Legality;
