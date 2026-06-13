with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Expression_Types;
with Editor.Ada_Selected_Name_Resolution;
with Editor.Ada_Subtype_Compatibility;

package body Editor.Ada_View_Aware_Compatibility is

   use type Editor.Ada_Expression_Types.Expression_Type_Id;
   use type Editor.Ada_Expression_Types.Expression_Type_Status;
   use type Editor.Ada_Selected_Name_Resolution.Selected_Name_Status;
   use type Editor.Ada_Subtype_Compatibility.Compatibility_Status;

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

   function Status_Fingerprint (Status : View_Compatibility_Status) return Natural is
   begin
      return View_Compatibility_Status'Pos (Status) * 1_000_003;
   end Status_Fingerprint;

   function Classify_Subtype_Compatibility
     (Info : Editor.Ada_Subtype_Compatibility.Compatibility_Info)
      return View_Compatibility_Status is
   begin
      case Info.Status is
         when Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Exact_Match
            | Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Universal_Integer_To_Integer
            | Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Universal_Real_To_Real
            | Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Universal_Integer_To_Real
            | Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Type_Graph_Exact
            | Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Type_Graph_Subtype_Of
            | Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Type_Graph_Derived_From
            | Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Type_Graph_Class_Wide =>
            return View_Compatibility_Compatible;
         when Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Private_View_Partial_View =>
            return View_Compatibility_Private_Partial_View;
         when Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Private_View_Full_View =>
            return View_Compatibility_Private_Full_View;
         when Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Private_View_Hidden_Full_View =>
            return View_Compatibility_Private_Full_View_Hidden;
         when Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Known_Incompatible =>
            return View_Compatibility_Known_Incompatible;
         when Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Indeterminate =>
            return View_Compatibility_Indeterminate;
         when others =>
            return View_Compatibility_Not_Checked;
      end case;
   end Classify_Subtype_Compatibility;

   function Classify_Expression
     (Info : Editor.Ada_Expression_Types.Expression_Type_Info)
      return View_Compatibility_Status is
   begin
      case Info.Status is
         when Editor.Ada_Expression_Types.Expression_Type_Selected_Name_Cross_Unit_Resolved =>
            return View_Compatibility_Compatible;
         when Editor.Ada_Expression_Types.Expression_Type_Selected_Name_Cross_Unit_Limited =>
            return View_Compatibility_Limited_Incomplete_View;
         when Editor.Ada_Expression_Types.Expression_Type_Selected_Name_Cross_Unit_Private =>
            return View_Compatibility_Cross_Unit_Private_View;
         when Editor.Ada_Expression_Types.Expression_Type_Selected_Name_Cross_Unit_Unresolved =>
            return View_Compatibility_Cross_Unit_Unresolved;
         when others =>
            case Info.Selected_Name_Status is
               when Editor.Ada_Selected_Name_Resolution.Selected_Name_Cross_Unit_Limited_Prefix =>
                  return View_Compatibility_Limited_Full_View_Hidden;
               when Editor.Ada_Selected_Name_Resolution.Selected_Name_Cross_Unit_Private_Prefix =>
                  return View_Compatibility_Cross_Unit_Private_View;
               when Editor.Ada_Selected_Name_Resolution.Selected_Name_Cross_Unit_Prefix_Missing
                  | Editor.Ada_Selected_Name_Resolution.Selected_Name_Cross_Unit_Prefix_Ambiguous
                  | Editor.Ada_Selected_Name_Resolution.Selected_Name_Cross_Unit_Prefix_Overflow =>
                  return View_Compatibility_Cross_Unit_Unresolved;
               when Editor.Ada_Selected_Name_Resolution.Selected_Name_Cross_Unit_Prefix_Found
                  | Editor.Ada_Selected_Name_Resolution.Selected_Name_Cross_Unit_Use_Prefix_Found =>
                  return View_Compatibility_Compatible;
               when others =>
                  return View_Compatibility_Not_Checked;
            end case;
      end case;
   end Classify_Expression;

   procedure Add_Entry
     (Model : in out View_Compatibility_Model;
      Info  : View_Compatibility_Info) is
   begin
      Model.Entries.Append (Info);
      case Info.Status is
         when View_Compatibility_Compatible =>
            Model.Compatible_Total := Model.Compatible_Total + 1;
         when View_Compatibility_Private_Partial_View
            | View_Compatibility_Private_Full_View
            | View_Compatibility_Private_Full_View_Hidden
            | View_Compatibility_Cross_Unit_Private_View =>
            Model.Private_Total := Model.Private_Total + 1;
         when View_Compatibility_Limited_Incomplete_View
            | View_Compatibility_Limited_Full_View_Hidden =>
            Model.Limited_Total := Model.Limited_Total + 1;
         when View_Compatibility_Cross_Unit_Unresolved =>
            Model.Unresolved_Total := Model.Unresolved_Total + 1;
         when View_Compatibility_Known_Incompatible =>
            Model.Incompatible_Total := Model.Incompatible_Total + 1;
         when View_Compatibility_Indeterminate =>
            Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
         when others =>
            null;
      end case;

      Model.Model_Fingerprint :=
        (Model.Model_Fingerprint * 65_599
         + Info.Fingerprint * 257
         + Natural (Info.Expression) * 17
         + Status_Fingerprint (Info.Status)) mod Natural'Last;
   end Add_Entry;

   function Build
     (Expressions : Editor.Ada_Expression_Types.Expression_Type_Model)
      return View_Compatibility_Model
   is
      Model : View_Compatibility_Model;
   begin
      for I in 1 .. Editor.Ada_Expression_Types.Expression_Type_Count (Expressions) loop
         declare
            Expr : constant Editor.Ada_Expression_Types.Expression_Type_Info :=
              Editor.Ada_Expression_Types.Expression_Type_At (Expressions, I);
            Status : constant View_Compatibility_Status := Classify_Expression (Expr);
         begin
            if Status /= View_Compatibility_Not_Checked then
               declare
                  Item : View_Compatibility_Info;
               begin
                  Item.Id := View_Compatibility_Id (Natural (Model.Entries.Length) + 1);
                  Item.Expression := Expr.Id;
                  Item.Node := Expr.Node;
                  Item.Source_Status := Expr.Status;
                  Item.Selected_Name := Expr.Selected_Name;
                  Item.Selected_Name_Status := Expr.Selected_Name_Status;
                  Item.Expected_Subtype := Expr.Expected_Subtype;
                  Item.Actual_Subtype := Expr.Inferred_Subtype;
                  Item.Cross_Unit_Target := Expr.Cross_Unit_Selected_Target;
                  Item.Cross_Unit_Selector := Expr.Cross_Unit_Selected_Selector;
                  Item.Status := Status;
                  Item.Start_Line := Expr.Start_Line;
                  Item.End_Line := Expr.End_Line;
                  Item.Fingerprint :=
                    (Expr.Fingerprint * 65_599
                     + Natural (Expr.Id) * 313
                     + Natural (Expr.Node) * 307
                     + Status_Fingerprint (Status)
                     + Hash_Text (To_String (Expr.Cross_Unit_Selected_Target)) * 17
                     + Hash_Text (To_String (Expr.Cross_Unit_Selected_Selector)) * 13)
                    mod Natural'Last;
                  Add_Entry (Model, Item);
               end;
            end if;
         end;
      end loop;

      Model.Model_Fingerprint :=
        (Model.Model_Fingerprint
         + Model.Compatible_Total * 10_007
         + Model.Private_Total * 1_009
         + Model.Limited_Total * 101
         + Model.Unresolved_Total * 53
         + Model.Incompatible_Total * 37
         + Model.Indeterminate_Total * 19) mod Natural'Last;
      return Model;
   end Build;

   function Entry_Count (Model : View_Compatibility_Model) return Natural is
   begin
      return Natural (Model.Entries.Length);
   end Entry_Count;

   function Entry_At
     (Model : View_Compatibility_Model;
      Index : Positive) return View_Compatibility_Info is
   begin
      if Index > Natural (Model.Entries.Length) then
         return (others => <>);
      end if;
      return Model.Entries.Element (Index);
   end Entry_At;

   function First_For_Expression
     (Model      : View_Compatibility_Model;
      Expression : Editor.Ada_Expression_Types.Expression_Type_Id)
      return View_Compatibility_Info is
   begin
      for Item of Model.Entries loop
         if Item.Expression = Expression then
            return Item;
         end if;
      end loop;
      return (others => <>);
   end First_For_Expression;

   function Count_Status
     (Model  : View_Compatibility_Model;
      Status : View_Compatibility_Status) return Natural
   is
      Count : Natural := 0;
   begin
      for Item of Model.Entries loop
         if Item.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Compatible_Count (Model : View_Compatibility_Model) return Natural is
   begin
      return Model.Compatible_Total;
   end Compatible_Count;

   function Private_View_Count (Model : View_Compatibility_Model) return Natural is
   begin
      return Model.Private_Total;
   end Private_View_Count;

   function Limited_View_Count (Model : View_Compatibility_Model) return Natural is
   begin
      return Model.Limited_Total;
   end Limited_View_Count;

   function Unresolved_Count (Model : View_Compatibility_Model) return Natural is
   begin
      return Model.Unresolved_Total;
   end Unresolved_Count;

   function Incompatible_Count (Model : View_Compatibility_Model) return Natural is
   begin
      return Model.Incompatible_Total;
   end Incompatible_Count;

   function Indeterminate_Count (Model : View_Compatibility_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : View_Compatibility_Model) return Natural is
   begin
      return Model.Model_Fingerprint;
   end Fingerprint;

end Editor.Ada_View_Aware_Compatibility;
