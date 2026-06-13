with Ada.Characters.Handling;
with Ada.Containers;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Freezing_Points is

   use type Ada.Containers.Count_Type;
   use type Editor.Ada_Declarative_Regions.Region_Id;
   use type Editor.Ada_Direct_Visibility.Declaration_Id;
   use type Editor.Ada_Direct_Visibility.Declaration_Kind;
   use type Editor.Ada_Direct_Visibility.Lookup_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Editor.Ada_Syntax_Tree.Node_Kind;
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
      Clean : constant String := Trimmed (Text);
      Dot   : Natural := 0;
      Tick  : Natural := 0;
   begin
      for Index in Clean'Range loop
         if Clean (Index) = '.' then
            Dot := Index;
         elsif Character'Pos (Clean (Index)) = 39 then
            Tick := Index;
            exit;
         end if;
      end loop;

      declare
         Base : constant String :=
           (if Tick /= 0 then Clean (Clean'First .. Tick - 1) else Clean);
      begin
         if Dot /= 0 and then Dot < Base'Last then
            return Ada.Characters.Handling.To_Lower (Trimmed (Base (Dot + 1 .. Base'Last)));
         else
            return Ada.Characters.Handling.To_Lower (Trimmed (Base));
         end if;
      end;
   end Normalized;

   function Child_Label
     (Tree   : Editor.Ada_Syntax_Tree.Tree_Type;
      Parent : Editor.Ada_Syntax_Tree.Node_Id;
      Kind   : Editor.Ada_Syntax_Tree.Node_Kind) return String is
   begin
      if Parent = Editor.Ada_Syntax_Tree.No_Node then
         return "";
      end if;

      for Index in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Parent) loop
         declare
            Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node
                (Tree, Editor.Ada_Syntax_Tree.Child_At (Tree, Parent, Index));
         begin
            if Child.Kind = Kind then
               return To_String (Child.Label);
            end if;
         end;
      end loop;

      return "";
   end Child_Label;

   function Is_Freezable_Declaration
     (Kind : Editor.Ada_Direct_Visibility.Declaration_Kind) return Boolean is
   begin
      return Kind = Editor.Ada_Direct_Visibility.Declaration_Type
        or else Kind = Editor.Ada_Direct_Visibility.Declaration_Subtype
        or else Kind = Editor.Ada_Direct_Visibility.Declaration_Subprogram
        or else Kind = Editor.Ada_Direct_Visibility.Declaration_Object
        or else Kind = Editor.Ada_Direct_Visibility.Declaration_Formal_Type
        or else Kind = Editor.Ada_Direct_Visibility.Declaration_Formal_Subprogram;
   end Is_Freezable_Declaration;

   function To_Freezable_Kind
     (Kind : Editor.Ada_Direct_Visibility.Declaration_Kind) return Freezable_Kind is
   begin
      if Kind = Editor.Ada_Direct_Visibility.Declaration_Type
        or else Kind = Editor.Ada_Direct_Visibility.Declaration_Formal_Type
      then
         return Freezable_Type;
      elsif Kind = Editor.Ada_Direct_Visibility.Declaration_Subtype then
         return Freezable_Subtype;
      elsif Kind = Editor.Ada_Direct_Visibility.Declaration_Subprogram
        or else Kind = Editor.Ada_Direct_Visibility.Declaration_Formal_Subprogram
      then
         return Freezable_Subprogram;
      elsif Kind = Editor.Ada_Direct_Visibility.Declaration_Object then
         return Freezable_Object;
      else
         return Freezable_Unknown;
      end if;
   end To_Freezable_Kind;

   function Type_For_Declaration
     (Types       : Editor.Ada_Type_Graph.Type_Model;
      Declaration : Editor.Ada_Direct_Visibility.Declaration_Id) return Editor.Ada_Type_Graph.Type_Id is
   begin
      for Index in 1 .. Editor.Ada_Type_Graph.Type_Count (Types) loop
         declare
            Info : constant Editor.Ada_Type_Graph.Type_Info :=
              Editor.Ada_Type_Graph.Type_At (Types, Index);
         begin
            if Info.Declaration = Declaration then
               return Info.Id;
            end if;
         end;
      end loop;

      return Editor.Ada_Type_Graph.No_Type;
   end Type_For_Declaration;

   function Is_Ancestor_Or_Self
     (Regions  : Editor.Ada_Declarative_Regions.Region_Model;
      Ancestor : Editor.Ada_Declarative_Regions.Region_Id;
      Child    : Editor.Ada_Declarative_Regions.Region_Id) return Boolean is
      Cursor : Editor.Ada_Declarative_Regions.Region_Id := Child;
   begin
      if Ancestor = Editor.Ada_Declarative_Regions.No_Region
        or else Child = Editor.Ada_Declarative_Regions.No_Region
      then
         return False;
      end if;

      while Cursor /= Editor.Ada_Declarative_Regions.No_Region loop
         if Cursor = Ancestor then
            return True;
         end if;
         Cursor := Editor.Ada_Declarative_Regions.Region (Regions, Cursor).Parent;
      end loop;

      return False;
   end Is_Ancestor_Or_Self;


   function Region_For_Line
     (Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Line    : Positive) return Editor.Ada_Declarative_Regions.Region_Id is
      Best       : Editor.Ada_Declarative_Regions.Region_Id := Editor.Ada_Declarative_Regions.No_Region;
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

   function Lookup_Freezable_Internal
     (Model  : Freezing_Model;
      Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Name   : String) return Freezable_Id is
      Norm  : constant String := Normalized (Name);
      Found : Freezable_Id := No_Freezable;
   begin
      for Index in 1 .. Natural (Model.Freezables.Length) loop
         declare
            Candidate : constant Freezable_Info := Model.Freezables (Index);
         begin
            if To_String (Candidate.Normalized_Name) = Norm
              and then (Candidate.Region = Region
                        or else Is_Ancestor_Or_Self (Regions, Candidate.Region, Region))
            then
               if Found /= No_Freezable then
                  return No_Freezable;
               end if;
               Found := Candidate.Id;
            end if;
         end;
      end loop;

      return Found;
   end Lookup_Freezable_Internal;

   procedure Note_Freeze
     (Model : in out Freezing_Model;
      Id    : Freezable_Id;
      Line  : Positive;
      Node  : Editor.Ada_Syntax_Tree.Node_Id;
      Cause : Freezing_Cause) is
   begin
      if Id = No_Freezable then
         return;
      end if;

      for Index in 1 .. Natural (Model.Freezables.Length) loop
         if Model.Freezables (Index).Id = Id then
            if Model.Freezables (Index).Status = Freezing_Not_Frozen
              or else Line < Model.Freezables (Index).First_Freeze_Line
            then
               Model.Freezables (Index).Status := Freezing_Frozen;
               Model.Freezables (Index).First_Freeze_Line := Line;
               Model.Freezables (Index).First_Freeze_Node := Node;
               Model.Freezables (Index).Cause := Cause;
               Model.Freezables (Index).Fingerprint :=
                 Mix (Model.Freezables (Index).Fingerprint,
                      Mix (Line, Natural (Editor.Ada_Freezing_Points.Freezing_Cause'Pos (Cause))));
            end if;
            return;
         end if;
      end loop;
   end Note_Freeze;

   procedure Clear (Model : in out Freezing_Model) is
   begin
      Model.Freezables.Clear;
      Model.Representations.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model) return Freezing_Model is
      Model : Freezing_Model;
   begin
      for Index in 1 .. Editor.Ada_Direct_Visibility.Declaration_Count (Visibility) loop
         declare
            Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
              Editor.Ada_Direct_Visibility.Declaration_At (Visibility, Index);
         begin
            if Is_Freezable_Declaration (Decl.Kind) then
               declare
                  Item : Freezable_Info;
               begin
                  Item.Id := Freezable_Id (Model.Freezables.Length + 1);
                  Item.Kind := To_Freezable_Kind (Decl.Kind);
                  Item.Declaration := Decl.Id;
                  Item.Type_Node := Type_For_Declaration (Types, Decl.Id);
                  Item.Node := Decl.Node;
                  Item.Region := Decl.Region;
                  Item.Name := Decl.Name;
                  Item.Normalized_Name := Decl.Normalized;
                  Item.Declaration_Line := Decl.Start_Line;
                  Item.First_Freeze_Line := Decl.Start_Line;
                  Item.Status := Freezing_Not_Frozen;
                  Item.Fingerprint :=
                    Mix (Natural (Item.Id),
                         Mix (Natural (Item.Declaration),
                              Mix (Natural (Item.Node), Decl.Start_Line)));
                  Model.Freezables.Append (Item);
               end;
            end if;
         end;
      end loop;

      --  Conservative freezing causes: an object declaration freezes its
      --  subtype mark, a matching subprogram body freezes the earlier
      --  subprogram declaration, and an instantiation freezes the generic
      --  designator where visible.
      for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
         declare
            Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
            Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
              (if Editor.Ada_Declarative_Regions.Has_Region_For_Node (Regions, Node.Id)
               then Editor.Ada_Declarative_Regions.Region_For_Node (Regions, Node.Id)
               else Region_For_Line (Regions, Node.Source_Span.Start_Line));
         begin
            if Node.Kind = Editor.Ada_Syntax_Tree.Node_Object_Declaration
              or else Node.Kind = Editor.Ada_Syntax_Tree.Node_Constant_Declaration
              or else Node.Kind = Editor.Ada_Syntax_Tree.Node_Component_Declaration
            then
               declare
                  Subtype_Text : constant String :=
                    Child_Label (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_Declaration_Subtype);
                  Target : constant Freezable_Id :=
                    Lookup_Freezable_Internal (Model, Regions, Region, Subtype_Text);
               begin
                  Note_Freeze (Model, Target, Node.Source_Span.Start_Line, Node.Id,
                               Freezing_Cause_Object_Declaration);
               end;
            elsif Node.Kind = Editor.Ada_Syntax_Tree.Node_Subprogram_Body then
               declare
                  Name : constant String :=
                    Child_Label (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_Declaration_Name);
                  Target : constant Freezable_Id :=
                    Lookup_Freezable_Internal (Model, Regions, Region, Name);
               begin
                  Note_Freeze (Model, Target, Node.Source_Span.Start_Line, Node.Id,
                               Freezing_Cause_Subprogram_Body);
               end;
            elsif Node.Kind = Editor.Ada_Syntax_Tree.Node_Instantiation then
               declare
                  Target_Text : constant String :=
                    Child_Label (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_Declaration_Target);
                  Target : constant Freezable_Id :=
                    Lookup_Freezable_Internal (Model, Regions, Region, Target_Text);
               begin
                  Note_Freeze (Model, Target, Node.Source_Span.Start_Line, Node.Id,
                               Freezing_Cause_Instantiation);
               end;
            end if;
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
         declare
            Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
         begin
            if Node.Kind = Editor.Ada_Syntax_Tree.Node_Representation_Clause then
               declare
                  Target_Text : constant String :=
                    Child_Label (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_Representation_Target);
                  Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
                    (if Editor.Ada_Declarative_Regions.Has_Region_For_Node (Regions, Node.Id)
                     then Editor.Ada_Declarative_Regions.Region_For_Node (Regions, Node.Id)
                     else Region_For_Line (Regions, Node.Source_Span.Start_Line));
                  Target : constant Freezable_Id :=
                    Lookup_Freezable_Internal (Model, Regions, Region, Target_Text);
                  Check : Representation_Freeze_Info;
               begin
                  Check.Clause_Node := Node.Id;
                  Check.Target_Name := To_Unbounded_String (Trimmed (Target_Text));
                  Check.Normalized_Target := To_Unbounded_String (Normalized (Target_Text));
                  Check.Target := Target;
                  Check.Clause_Line := Node.Source_Span.Start_Line;

                  if Target = No_Freezable then
                     Check.Status := Representation_Target_Unresolved;
                     Check.Freeze_Line := Node.Source_Span.Start_Line;
                  else
                     declare
                        Target_Info : constant Freezable_Info := Freezable_Node (Model, Target);
                     begin
                        Check.Freeze_Line := Target_Info.First_Freeze_Line;
                        if Target_Info.Kind = Freezable_Unknown then
                           Check.Status := Representation_Target_Not_Freezable;
                        elsif Target_Info.Status = Freezing_Not_Frozen then
                           Check.Status := Representation_Target_Not_Frozen;
                        elsif Node.Source_Span.Start_Line < Target_Info.First_Freeze_Line then
                           Check.Status := Representation_Before_Freezing;
                        elsif Node.Source_Span.Start_Line = Target_Info.First_Freeze_Line then
                           Check.Status := Representation_At_Freezing_Point;
                        else
                           Check.Status := Representation_After_Freezing;
                        end if;
                     end;
                  end if;

                  Check.Fingerprint :=
                    Mix (Natural (Check.Clause_Node),
                         Mix (Natural (Check.Target),
                              Mix (Check.Clause_Line,
                                   Mix (Check.Freeze_Line,
                                        Natural (Representation_Freezing_Status'Pos (Check.Status))))));
                  Model.Representations.Append (Check);
               end;
            end if;
         end;
      end loop;

      for Index in 1 .. Natural (Model.Freezables.Length) loop
         Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Model.Freezables (Index).Fingerprint);
      end loop;
      for Index in 1 .. Natural (Model.Representations.Length) loop
         Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Model.Representations (Index).Fingerprint);
      end loop;

      return Model;
   end Build;

   function Freezable_Count (Model : Freezing_Model) return Natural is
   begin
      return Natural (Model.Freezables.Length);
   end Freezable_Count;

   function Freezable_At
     (Model : Freezing_Model;
      Index : Positive) return Freezable_Info is
   begin
      return Model.Freezables (Index);
   end Freezable_At;

   function Freezable_Node
     (Model : Freezing_Model;
      Id    : Freezable_Id) return Freezable_Info is
   begin
      if Id = No_Freezable then
         return (others => <>);
      end if;

      for Index in 1 .. Natural (Model.Freezables.Length) loop
         if Model.Freezables (Index).Id = Id then
            return Model.Freezables (Index);
         end if;
      end loop;

      return (others => <>);
   end Freezable_Node;

   function Lookup_Freezable
     (Model  : Freezing_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Name   : String) return Freezable_Id is
      Norm : constant String := Normalized (Name);
   begin
      for Index in 1 .. Natural (Model.Freezables.Length) loop
         if To_String (Model.Freezables (Index).Normalized_Name) = Norm
           and then Model.Freezables (Index).Region = Region
         then
            return Model.Freezables (Index).Id;
         end if;
      end loop;

      for Index in 1 .. Natural (Model.Freezables.Length) loop
         if To_String (Model.Freezables (Index).Normalized_Name) = Norm then
            return Model.Freezables (Index).Id;
         end if;
      end loop;

      return No_Freezable;
   end Lookup_Freezable;

   function Freezing_Status_For
     (Model  : Freezing_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Name   : String) return Freezing_Status is
      Id : constant Freezable_Id := Lookup_Freezable (Model, Region, Name);
   begin
      if Id = No_Freezable then
         return Freezing_Target_Unresolved;
      end if;
      return Freezable_Node (Model, Id).Status;
   end Freezing_Status_For;

   function Representation_Check_Count (Model : Freezing_Model) return Natural is
   begin
      return Natural (Model.Representations.Length);
   end Representation_Check_Count;

   function Representation_Check_At
     (Model : Freezing_Model;
      Index : Positive) return Representation_Freeze_Info is
   begin
      return Model.Representations (Index);
   end Representation_Check_At;

   function Representation_Check_For_Clause
     (Model : Freezing_Model;
      Clause: Editor.Ada_Syntax_Tree.Node_Id) return Representation_Freeze_Info is
   begin
      for Index in 1 .. Natural (Model.Representations.Length) loop
         if Model.Representations (Index).Clause_Node = Clause then
            return Model.Representations (Index);
         end if;
      end loop;

      return (others => <>);
   end Representation_Check_For_Clause;

   function Fingerprint (Model : Freezing_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Freezing_Points;
