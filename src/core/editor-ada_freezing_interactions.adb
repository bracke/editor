with Ada.Characters.Handling;
with Ada.Containers;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Freezing_Interactions is

   pragma Suppress (Overflow_Check);

   use type Ada.Containers.Count_Type;
   use type Editor.Ada_Freezing_Points.Freezable_Id;
   use type Editor.Ada_Freezing_Points.Freezable_Kind;
   use type Editor.Ada_Freezing_Points.Freezing_Status;
   use type Editor.Ada_Generic_Contracts.Generic_Instance_Status;
   use type Editor.Ada_Declarative_Regions.Region_Id;
   use type Editor.Ada_Private_View_Visibility.Private_View_Id;
   use type Editor.Ada_Private_View_Visibility.Private_View_Status;
   use type Editor.Ada_Syntax_Tree.Node_Kind;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Editor.Ada_Type_Graph.Type_Id;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 131) + B + 31) mod 2_147_483_647;
   end Mix;

   function Trimmed (Text : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Trimmed;

   function Normalized (Text : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower (Trimmed (Text));
   end Normalized;

   function Is_Body_Node (Kind : Editor.Ada_Syntax_Tree.Node_Kind) return Boolean is
   begin
      return Kind = Editor.Ada_Syntax_Tree.Node_Package_Body
        or else Kind = Editor.Ada_Syntax_Tree.Node_Subprogram_Body
        or else Kind = Editor.Ada_Syntax_Tree.Node_Task_Body
        or else Kind = Editor.Ada_Syntax_Tree.Node_Protected_Body
        or else Kind = Editor.Ada_Syntax_Tree.Node_Entry_Body;
   end Is_Body_Node;

   function Region_For_Line
     (Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Line    : Positive) return Editor.Ada_Declarative_Regions.Region_Id is
      Best       : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Best_Depth : Natural := 0;
   begin
      for Index in 1 .. Editor.Ada_Declarative_Regions.Region_Count (Regions) loop
         declare
            Info : constant Editor.Ada_Declarative_Regions.Region_Info :=
              Editor.Ada_Declarative_Regions.Region_At (Regions, Index);
         begin
            if Line >= Info.Start_Line and then Line <= Info.End_Line
              and then (Best = Editor.Ada_Declarative_Regions.No_Region
                        or else Info.Depth >= Best_Depth)
            then
               Best := Info.Id;
               Best_Depth := Info.Depth;
            end if;
         end;
      end loop;
      return Best;
   end Region_For_Line;

   procedure Append
     (Model : in out Freezing_Interaction_Model;
      Item  : Freezing_Interaction_Info) is
      Next : Freezing_Interaction_Info := Item;
   begin
      Next.Id := Freezing_Interaction_Id (Model.Interactions.Length + 1);
      Next.Fingerprint :=
        Mix (Natural (Next.Id),
             Mix (Natural (Next.Node),
                  Mix (Natural (Next.Region),
                       Mix (Next.Line,
                            Mix (Natural (Next.Freezable),
                                 Natural (Freezing_Interaction_Status'Pos (Next.Status)))))));
      Model.Interactions.Append (Next);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Next.Fingerprint);
   end Append;

   procedure Clear (Model : in out Freezing_Interaction_Model) is
   begin
      Model.Interactions.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Tree          : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions       : Editor.Ada_Declarative_Regions.Region_Model;
      Freezing      : Editor.Ada_Freezing_Points.Freezing_Model;
      Types         : Editor.Ada_Type_Graph.Type_Model;
      Private_Views : Editor.Ada_Private_View_Visibility.Private_View_Model;
      Generics      : Editor.Ada_Generic_Contracts.Generic_Contract_Model)
      return Freezing_Interaction_Model is
      Model : Freezing_Interaction_Model;
   begin
      --  Generic instances are freezing events for their generic designator.
      --  The underlying freezing model already records the conservative first
      --  freeze line; this projection keeps the instance-specific target state
      --  available to representation/freezing diagnostics.
      for Index in 1 .. Editor.Ada_Generic_Contracts.Instance_Count (Generics) loop
         declare
            Instance : constant Editor.Ada_Generic_Contracts.Generic_Instance_Info :=
              Editor.Ada_Generic_Contracts.Instance_At (Generics, Index);
            Target : constant Editor.Ada_Freezing_Points.Freezable_Id :=
              Editor.Ada_Freezing_Points.Lookup_Freezable
                (Freezing, Instance.Region, To_String (Instance.Generic_Name));
            Item : Freezing_Interaction_Info;
         begin
            Item.Node := Instance.Node;
            Item.Region := Instance.Region;
            Item.Line := Instance.Start_Line;
            Item.Name := Instance.Generic_Name;
            Item.Normalized_Name := To_Unbounded_String (Normalized (To_String (Instance.Generic_Name)));
            Item.Freezable := Target;
            Item.Instance := Instance.Id;

            if Instance.Status /= Editor.Ada_Generic_Contracts.Generic_Instance_Record_Valid then
               Item.Status := Freezing_Interaction_Generic_Target_Unresolved;
            elsif Target = Editor.Ada_Freezing_Points.No_Freezable then
               --  Generic package declarations are valid freezing designators
               --  even when the lower freezable model has not materialized a
               --  package-generic target.  Preserve the instance-specific
               --  freezing fact so downstream representation diagnostics can
               --  distinguish a valid instance from a malformed/unresolved one.
               Item.Status := Freezing_Interaction_Generic_Instance_Freezes_Target;
            elsif Editor.Ada_Freezing_Points.Freezing_Status_For
              (Freezing, Instance.Region, To_String (Instance.Generic_Name)) =
              Editor.Ada_Freezing_Points.Freezing_Target_Ambiguous
            then
               Item.Status := Freezing_Interaction_Generic_Target_Ambiguous;
            else
               declare
                  Target_Info : constant Editor.Ada_Freezing_Points.Freezable_Info :=
                    Editor.Ada_Freezing_Points.Freezable_Node (Freezing, Target);
               begin
                  if Target_Info.Kind = Editor.Ada_Freezing_Points.Freezable_Unknown then
                     Item.Status := Freezing_Interaction_Generic_Target_Not_Freezable;
                  else
                     Item.Status := Freezing_Interaction_Generic_Instance_Freezes_Target;
                  end if;
               end;
            end if;
            Append (Model, Item);
         end;
      end loop;

      --  Private/full-view freezing contexts.  The full view is only a
      --  freezing-visible type in private parts and bodies; visible clients
      --  keep seeing the partial view.  This records both sides without
      --  changing type-graph ownership.
      for Index in 1 .. Editor.Ada_Private_View_Visibility.Private_View_Count (Private_Views) loop
         declare
            View : constant Editor.Ada_Private_View_Visibility.Private_View_Info :=
              Editor.Ada_Private_View_Visibility.Private_View_At (Private_Views, Index);
            Partial_Info : constant Editor.Ada_Type_Graph.Type_Info :=
              Editor.Ada_Type_Graph.Type_Node (Types, View.Partial_Type);
            Full_Info : constant Editor.Ada_Type_Graph.Type_Info :=
              Editor.Ada_Type_Graph.Type_Node (Types, View.Full_Type);
            Partial : Freezing_Interaction_Info;
            Full    : Freezing_Interaction_Info;
         begin
            Partial.Node := Partial_Info.Node;
            Partial.Region := Partial_Info.Region;
            Partial.Line := Partial_Info.Start_Line;
            Partial.Name := Partial_Info.Name;
            Partial.Normalized_Name := Partial_Info.Normalized_Name;
            Partial.Partial_Type := View.Partial_Type;
            Partial.Full_Type := View.Full_Type;
            Partial.Private_View := View.Id;
            Partial.Status := Freezing_Interaction_Private_Partial_View;
            Append (Model, Partial);

            Full.Node := Full_Info.Node;
            Full.Region := Full_Info.Region;
            Full.Line := Full_Info.Start_Line;
            Full.Name := Full_Info.Name;
            Full.Normalized_Name := Full_Info.Normalized_Name;
            Full.Partial_Type := View.Partial_Type;
            Full.Full_Type := View.Full_Type;
            Full.Private_View := View.Id;
            if View.Status = Editor.Ada_Private_View_Visibility.Private_View_Full_View_Linked then
               if View.Package_Body_Region /= Editor.Ada_Declarative_Regions.No_Region
                 or else View.Private_Part_Node /= Editor.Ada_Syntax_Tree.No_Node
               then
                  Full.Status := Freezing_Interaction_Private_Full_View_Visible;
               else
                  Full.Status := Freezing_Interaction_Private_Full_View_Hidden;
               end if;
            elsif View.Status = Editor.Ada_Private_View_Visibility.Private_View_Full_View_Unresolved then
               Full.Status := Freezing_Interaction_Private_Full_View_Unresolved;
            else
               Full.Status := Freezing_Interaction_Private_Full_View_Hidden;
            end if;
            Append (Model, Full);
         end;
      end loop;

      --  Body_Info regions are freezing-relevant contexts for completions and
      --  private full views.  The entry is intentionally region-level; deeper
      --  declaration conformance remains in the body/spec semantic layer.
      for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
         declare
            Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
         begin
            if Is_Body_Node (Node.Kind) then
               declare
                  Item : Freezing_Interaction_Info;
               begin
                  Item.Node := Node.Id;
                  Item.Region :=
                    (if Editor.Ada_Declarative_Regions.Has_Region_For_Node (Regions, Node.Id)
                     then Editor.Ada_Declarative_Regions.Region_For_Node (Regions, Node.Id)
                     else Region_For_Line (Regions, Node.Source_Span.Start_Line));
                  Item.Line := Node.Source_Span.Start_Line;
                  Item.Name := Node.Label;
                  Item.Normalized_Name := To_Unbounded_String (Normalized (To_String (Node.Label)));
                  Item.Status := Freezing_Interaction_Body_Context;
                  Append (Model, Item);
               end;
            end if;
         end;
      end loop;

      return Model;
   end Build;

   function Interaction_Count (Model : Freezing_Interaction_Model) return Natural is
   begin
      return Natural (Model.Interactions.Length);
   end Interaction_Count;

   function Interaction_At
     (Model : Freezing_Interaction_Model;
      Index : Positive) return Freezing_Interaction_Info is
   begin
      return Model.Interactions (Index);
   end Interaction_At;

   function Count_Status
     (Model  : Freezing_Interaction_Model;
      Status : Freezing_Interaction_Status) return Natural is
      Result : Natural := 0;
   begin
      for Index in 1 .. Natural (Model.Interactions.Length) loop
         if Model.Interactions (Index).Status = Status then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Count_Status;

   function Generic_Instance_Freeze_Count
     (Model : Freezing_Interaction_Model) return Natural is
   begin
      return Count_Status (Model, Freezing_Interaction_Generic_Instance_Freezes_Target);
   end Generic_Instance_Freeze_Count;

   function Generic_Instance_Target_Error_Count
     (Model : Freezing_Interaction_Model) return Natural is
   begin
      return Count_Status (Model, Freezing_Interaction_Generic_Target_Unresolved)
        + Count_Status (Model, Freezing_Interaction_Generic_Target_Ambiguous)
        + Count_Status (Model, Freezing_Interaction_Generic_Target_Not_Freezable);
   end Generic_Instance_Target_Error_Count;

   function Private_Partial_View_Count
     (Model : Freezing_Interaction_Model) return Natural is
   begin
      return Count_Status (Model, Freezing_Interaction_Private_Partial_View);
   end Private_Partial_View_Count;

   function Private_Full_View_Visible_Count
     (Model : Freezing_Interaction_Model) return Natural is
   begin
      return Count_Status (Model, Freezing_Interaction_Private_Full_View_Visible);
   end Private_Full_View_Visible_Count;

   function Private_Full_View_Hidden_Count
     (Model : Freezing_Interaction_Model) return Natural is
   begin
      return Count_Status (Model, Freezing_Interaction_Private_Full_View_Hidden);
   end Private_Full_View_Hidden_Count;

   function Body_Context_Count
     (Model : Freezing_Interaction_Model) return Natural is
   begin
      return Count_Status (Model, Freezing_Interaction_Body_Context);
   end Body_Context_Count;

   function Fingerprint (Model : Freezing_Interaction_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Freezing_Interactions;
