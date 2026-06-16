with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;

package body Editor.Ada_Expected_Type_Contexts is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Call_Resolution.Call_Resolution_Id;
   use type Editor.Ada_Declarative_Regions.Region_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Editor.Ada_Syntax_Tree.Node_Kind;

   function To_String
     (Value : Ada.Strings.Unbounded.Unbounded_String) return String
      renames Ada.Strings.Unbounded.To_String;

   function To_Unbounded_String (Value : String)
      return Ada.Strings.Unbounded.Unbounded_String
      renames Ada.Strings.Unbounded.To_Unbounded_String;

   procedure Mix (Model : in out Expected_Context_Model; Value : Natural) is
   begin
      Model.Result_Fingerprint :=
        (Model.Result_Fingerprint * 65599 + Value + 229) mod Natural'Last;
   end Mix;

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

   function Normalize (Text : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower (Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both));
   end Normalize;

   function Empty_Context return Expected_Context_Info is
   begin
      return (Id => No_Expected_Context,
              Node => Editor.Ada_Syntax_Tree.No_Node,
              Context_Node => Editor.Ada_Syntax_Tree.No_Node,
              Region => Editor.Ada_Declarative_Regions.No_Region,
              Resolution => Editor.Ada_Call_Resolution.No_Call_Resolution,
              Kind => Expected_Context_None,
              Expected_Subtype => Ada.Strings.Unbounded.Null_Unbounded_String,
              Normalized_Subtype => Ada.Strings.Unbounded.Null_Unbounded_String,
              Status => Expected_Context_Not_Checked,
              Start_Line => 1,
              End_Line => 1,
              Fingerprint => 0);
   end Empty_Context;

   function Region_For_Node
     (Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Node    : Editor.Ada_Syntax_Tree.Node_Id)
      return Editor.Ada_Declarative_Regions.Region_Id is
   begin
      return Editor.Ada_Declarative_Regions.Region_For_Node (Regions, Node);
   exception
      when others =>
         return Editor.Ada_Declarative_Regions.No_Region;
   end Region_For_Node;

   function Child_Label
     (Tree   : Editor.Ada_Syntax_Tree.Tree_Type;
      Parent : Editor.Ada_Syntax_Tree.Node_Id;
      Kind   : Editor.Ada_Syntax_Tree.Node_Kind) return String
   is
      Child : Editor.Ada_Syntax_Tree.Node_Id;
      Info  : Editor.Ada_Syntax_Tree.Node_Info;
   begin
      if Parent = Editor.Ada_Syntax_Tree.No_Node then
         return "";
      end if;
      for Index in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Parent) loop
         Child := Editor.Ada_Syntax_Tree.Child_At (Tree, Parent, Index);
         Info := Editor.Ada_Syntax_Tree.Node (Tree, Child);
         if Info.Kind = Kind then
            return Ada.Strings.Fixed.Trim (To_String (Info.Label), Ada.Strings.Both);
         end if;
      end loop;
      return "";
   end Child_Label;

   function Enclosing_Node_Of_Kind
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Node : Editor.Ada_Syntax_Tree.Node_Id;
      Kind : Editor.Ada_Syntax_Tree.Node_Kind)
      return Editor.Ada_Syntax_Tree.Node_Id
   is
      Current : Editor.Ada_Syntax_Tree.Node_Id := Node;
      Info    : Editor.Ada_Syntax_Tree.Node_Info;
   begin
      while Current /= Editor.Ada_Syntax_Tree.No_Node loop
         Info := Editor.Ada_Syntax_Tree.Node (Tree, Current);
         if Info.Kind = Kind then
            return Current;
         end if;
         Current := Info.Parent;
      end loop;
      return Editor.Ada_Syntax_Tree.No_Node;
   end Enclosing_Node_Of_Kind;

   function Enclosing_Declaration_Default
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Node : Editor.Ada_Syntax_Tree.Node_Id)
      return Editor.Ada_Syntax_Tree.Node_Id is
   begin
      return Enclosing_Node_Of_Kind
        (Tree, Node, Editor.Ada_Syntax_Tree.Node_Declaration_Default);
   end Enclosing_Declaration_Default;

   function Enclosing_Return
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Node : Editor.Ada_Syntax_Tree.Node_Id)
      return Editor.Ada_Syntax_Tree.Node_Id is
   begin
      return Enclosing_Node_Of_Kind
        (Tree, Node, Editor.Ada_Syntax_Tree.Node_Return_Statement);
   end Enclosing_Return;

   function Declaration_For_Detail
     (Tree   : Editor.Ada_Syntax_Tree.Tree_Type;
      Detail : Editor.Ada_Syntax_Tree.Node_Id)
      return Editor.Ada_Syntax_Tree.Node_Id
   is
      Parent : constant Editor.Ada_Syntax_Tree.Node_Id :=
        Editor.Ada_Syntax_Tree.Node (Tree, Detail).Parent;
   begin
      return Parent;
   end Declaration_For_Detail;

   function Declaration_Context_Kind
     (Tree        : Editor.Ada_Syntax_Tree.Tree_Type;
      Declaration : Editor.Ada_Syntax_Tree.Node_Id) return Expected_Context_Kind
   is
      Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
        Editor.Ada_Syntax_Tree.Node (Tree, Declaration);
   begin
      if Info.Kind = Editor.Ada_Syntax_Tree.Node_Object_Declaration then
         return Expected_Context_Object_Default;
      elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Constant_Declaration then
         return Expected_Context_Constant_Default;
      elsif Declaration /= Editor.Ada_Syntax_Tree.No_Node then
         return Expected_Context_Declaration_Default;
      else
         return Expected_Context_None;
      end if;
   end Declaration_Context_Kind;

   function Result_Subtype_For_Region
     (Profiles : Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model;
      Region   : Editor.Ada_Declarative_Regions.Region_Id) return String
   is
      Info : Editor.Ada_Call_Profile_Shapes.Callable_Profile_Info;
   begin
      if Region = Editor.Ada_Declarative_Regions.No_Region then
         return "";
      end if;
      for Index in 1 .. Editor.Ada_Call_Profile_Shapes.Callable_Profile_Count (Profiles) loop
         Info := Editor.Ada_Call_Profile_Shapes.Callable_Profile_At (Profiles, Index);
         if Info.Region = Region and then Info.Has_Result then
            return Ada.Strings.Fixed.Trim (To_String (Info.Result_Subtype), Ada.Strings.Both);
         end if;
      end loop;
      return "";
   end Result_Subtype_For_Region;

   procedure Add_Context
     (Model       : in out Expected_Context_Model;
      Tree        : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions     : Editor.Ada_Declarative_Regions.Region_Model;
      Profiles    : Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model;
      Resolution  : Editor.Ada_Call_Resolution.Call_Resolution_Info)
   is
      Node_Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
        Editor.Ada_Syntax_Tree.Node (Tree, Resolution.Call_Node);
      Id : constant Expected_Context_Id :=
        Expected_Context_Id (Natural (Model.Contexts.Length) + 1);
      Info : Expected_Context_Info := Empty_Context;
      Default_Node : constant Editor.Ada_Syntax_Tree.Node_Id :=
        Enclosing_Declaration_Default (Tree, Resolution.Call_Node);
      Return_Node : constant Editor.Ada_Syntax_Tree.Node_Id :=
        Enclosing_Return (Tree, Resolution.Call_Node);
      Decl_Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Expected : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Region : Editor.Ada_Declarative_Regions.Region_Id :=
        Region_For_Node (Regions, Resolution.Call_Node);
   begin
      Info.Id := Id;
      Info.Node := Resolution.Call_Node;
      Info.Resolution := Resolution.Id;
      Info.Region := Region;
      Info.Start_Line := Node_Info.Source_Span.Start_Line;
      Info.End_Line := Node_Info.Source_Span.End_Line;

      if Resolution.Call_Node = Editor.Ada_Syntax_Tree.No_Node then
         Info.Status := Expected_Context_No_Call_Node;
      elsif Default_Node /= Editor.Ada_Syntax_Tree.No_Node then
         Decl_Node := Declaration_For_Detail (Tree, Default_Node);
         Info.Context_Node := Decl_Node;
         Info.Kind := Declaration_Context_Kind (Tree, Decl_Node);
         Expected := To_Unbounded_String
           (Child_Label (Tree, Decl_Node, Editor.Ada_Syntax_Tree.Node_Declaration_Subtype));
         if To_String (Expected) = "" then
            Info.Status := Expected_Context_Context_Without_Subtype;
         else
            Info.Status := Expected_Context_Found;
         end if;
      elsif Return_Node /= Editor.Ada_Syntax_Tree.No_Node then
         Info.Context_Node := Return_Node;
         Info.Kind := Expected_Context_Return_Statement;
         Expected := To_Unbounded_String (Result_Subtype_For_Region (Profiles, Region));
         if To_String (Expected) = "" then
            Info.Status := Expected_Context_Context_Without_Subtype;
         else
            Info.Status := Expected_Context_Found;
         end if;
      else
         Info.Status := Expected_Context_No_Context;
      end if;

      Info.Expected_Subtype := Expected;
      Info.Normalized_Subtype := To_Unbounded_String (Normalize (To_String (Expected)));
      Info.Fingerprint :=
        (Expected_Context_Status'Pos (Info.Status) * 1000003
         + Expected_Context_Kind'Pos (Info.Kind) * 65537
         + Natural (Info.Node) * 1009
         + Natural (Info.Context_Node) * 503
         + Natural (Info.Region) * 211
         + Natural (Info.Resolution) * 97
         + Hash_Text (To_String (Info.Expected_Subtype))) mod Natural'Last;
      Model.Contexts.Append (Info);
      Mix (Model, Info.Fingerprint);
   end Add_Context;

   procedure Clear (Model : in out Expected_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Tree        : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions     : Editor.Ada_Declarative_Regions.Region_Model;
      Profiles    : Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model;
      Resolutions : Editor.Ada_Call_Resolution.Call_Resolution_Model)
      return Expected_Context_Model
   is
      Model : Expected_Context_Model;
   begin
      Clear (Model);
      for Index in 1 .. Editor.Ada_Call_Resolution.Call_Resolution_Count (Resolutions) loop
         Add_Context
           (Model, Tree, Regions, Profiles,
            Editor.Ada_Call_Resolution.Call_Resolution_At (Resolutions, Index));
      end loop;
      Mix (Model, Editor.Ada_Syntax_Tree.Fingerprint (Tree));
      Mix (Model, Editor.Ada_Declarative_Regions.Fingerprint (Regions));
      Mix (Model, Editor.Ada_Call_Profile_Shapes.Fingerprint (Profiles));
      Mix (Model, Editor.Ada_Call_Resolution.Fingerprint (Resolutions));
      return Model;
   end Build;



   function Build
     (Tree        : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions     : Editor.Ada_Declarative_Regions.Region_Model;
      Resolutions : Editor.Ada_Call_Resolution.Call_Resolution_Model)
      return Expected_Context_Model
   is
      Profiles : Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model;
   begin
      return Build (Tree, Regions, Profiles, Resolutions);
   end Build;

   function Has_Expected_Contexts (Model : Expected_Context_Model) return Boolean is
   begin
      return not Model.Contexts.Is_Empty;
   end Has_Expected_Contexts;

   function Expected_Context_Count (Model : Expected_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Expected_Context_Count;

   function Expected_Context_At
     (Model : Expected_Context_Model;
      Index : Positive) return Expected_Context_Info is
   begin
      if Index > Natural (Model.Contexts.Length) then
         return Empty_Context;
      end if;
      return Model.Contexts (Index);
   end Expected_Context_At;

   function Expected_Context
     (Model : Expected_Context_Model;
      Id    : Expected_Context_Id) return Expected_Context_Info is
   begin
      if Id = No_Expected_Context
        or else Natural (Id) > Natural (Model.Contexts.Length)
      then
         return Empty_Context;
      end if;
      return Model.Contexts (Positive (Id));
   end Expected_Context;

   function Expected_Context_For_Node
     (Model : Expected_Context_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Expected_Context_Info is
   begin
      for Info of Model.Contexts loop
         if Info.Node = Node then
            return Info;
         end if;
      end loop;
      return Empty_Context;
   end Expected_Context_For_Node;

   function Count_Status
     (Model  : Expected_Context_Model;
      Status : Expected_Context_Status) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Model.Contexts loop
         if Info.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind
     (Model : Expected_Context_Model;
      Kind  : Expected_Context_Kind) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Model.Contexts loop
         if Info.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Fingerprint (Model : Expected_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Expected_Type_Contexts;
