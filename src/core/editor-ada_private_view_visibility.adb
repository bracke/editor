with Ada.Characters.Handling;
with Ada.Containers;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Private_View_Visibility is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Declarative_Regions.Region_Id;
   use type Editor.Ada_Declarative_Regions.Region_Kind;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Editor.Ada_Syntax_Tree.Node_Kind;
   use type Editor.Ada_Type_Graph.Type_Id;
   use type Editor.Ada_Type_Graph.Type_View_Status;
   use type Ada.Containers.Count_Type;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 131) + B + 17) mod 2_147_483_647;
   end Mix;

   function Normalized (Text : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower (Text);
   end Normalized;

   function Region_Name
     (Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Region  : Editor.Ada_Declarative_Regions.Region_Id) return String is
   begin
      if Region = Editor.Ada_Declarative_Regions.No_Region then
         return "";
      end if;
      return Normalized (To_String (Editor.Ada_Declarative_Regions.Region (Regions, Region).Label));
   end Region_Name;

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

   function Find_Private_Part_Node
     (Tree        : Editor.Ada_Syntax_Tree.Tree_Type;
      Package_Reg : Editor.Ada_Declarative_Regions.Region_Info) return Editor.Ada_Syntax_Tree.Node_Id is
   begin
      for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
         declare
            Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
         begin
            if Node.Kind = Editor.Ada_Syntax_Tree.Node_Private_Part
              and then Node.Source_Span.Start_Line >= Package_Reg.Start_Line
              and then Node.Source_Span.Start_Line <= Package_Reg.End_Line
            then
               return Node.Id;
            end if;
         end;
      end loop;

      return Editor.Ada_Syntax_Tree.No_Node;
   end Find_Private_Part_Node;

   function Find_Package_Body_Region
     (Regions     : Editor.Ada_Declarative_Regions.Region_Model;
      Package_Reg : Editor.Ada_Declarative_Regions.Region_Info) return Editor.Ada_Declarative_Regions.Region_Id is
      Name : constant String := Normalized (To_String (Package_Reg.Label));
   begin
      for Index in 1 .. Editor.Ada_Declarative_Regions.Region_Count (Regions) loop
         declare
            Candidate : constant Editor.Ada_Declarative_Regions.Region_Info :=
              Editor.Ada_Declarative_Regions.Region_At (Regions, Index);
         begin
            if Candidate.Kind = Editor.Ada_Declarative_Regions.Region_Package_Body
              and then Normalized (To_String (Candidate.Label)) = Name
            then
               return Candidate.Id;
            end if;
         end;
      end loop;

      return Editor.Ada_Declarative_Regions.No_Region;
   end Find_Package_Body_Region;

   procedure Clear (Model : in out Private_View_Model) is
   begin
      Model.Views.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Tree    : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Types   : Editor.Ada_Type_Graph.Type_Model) return Private_View_Model is
      Model : Private_View_Model;
   begin
      for Index in 1 .. Editor.Ada_Type_Graph.Type_Count (Types) loop
         declare
            Info : constant Editor.Ada_Type_Graph.Type_Info :=
              Editor.Ada_Type_Graph.Type_At (Types, Index);
         begin
            if Info.View_Status = Editor.Ada_Type_Graph.Type_View_Private_Partial then
               declare
                  Package_Reg : constant Editor.Ada_Declarative_Regions.Region_Info :=
                    Editor.Ada_Declarative_Regions.Region (Regions, Info.Region);
                  Private_Node : constant Editor.Ada_Syntax_Tree.Node_Id :=
                    Find_Private_Part_Node (Tree, Package_Reg);
                  View : Private_View_Info;
               begin
                  View.Id := Private_View_Id (Model.Views.Length + 1);
                  View.Partial_Type := Info.Id;
                  View.Full_Type := Info.Full_View;
                  View.Package_Spec_Region := Info.Region;
                  View.Package_Body_Region := Find_Package_Body_Region (Regions, Package_Reg);
                  View.Private_Part_Node := Private_Node;
                  if Private_Node /= Editor.Ada_Syntax_Tree.No_Node then
                     View.Private_Part_Line :=
                       Editor.Ada_Syntax_Tree.Node (Tree, Private_Node).Source_Span.Start_Line;
                  else
                     View.Private_Part_Line := Info.Start_Line;
                  end if;

                  if Info.Full_View = Editor.Ada_Type_Graph.No_Type then
                     View.Status := Private_View_Full_View_Unresolved;
                  elsif Private_Node = Editor.Ada_Syntax_Tree.No_Node then
                     View.Status := Private_View_Missing_Private_Part;
                  else
                     View.Status := Private_View_Full_View_Linked;
                  end if;

                  View.Fingerprint :=
                    Mix (Natural (View.Partial_Type),
                         Mix (Natural (View.Full_Type),
                              Mix (Natural (View.Package_Spec_Region),
                                   Mix (Natural (View.Package_Body_Region), View.Private_Part_Line))));
                  Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, View.Fingerprint);
                  Model.Views.Append (View);
               end;
            end if;
         end;
      end loop;

      return Model;
   end Build;

   function Private_View_Count (Model : Private_View_Model) return Natural is
   begin
      return Natural (Model.Views.Length);
   end Private_View_Count;

   function Private_View_At
     (Model : Private_View_Model;
      Index : Positive) return Private_View_Info is
   begin
      return Model.Views (Index);
   end Private_View_At;

   function Private_View_For_Partial
     (Model        : Private_View_Model;
      Partial_Type : Editor.Ada_Type_Graph.Type_Id) return Private_View_Id is
   begin
      for Index in 1 .. Natural (Model.Views.Length) loop
         if Model.Views (Index).Partial_Type = Partial_Type then
            return Model.Views (Index).Id;
         end if;
      end loop;

      return No_Private_View;
   end Private_View_For_Partial;

   function Private_View_For_Full
     (Model     : Private_View_Model;
      Full_Type : Editor.Ada_Type_Graph.Type_Id) return Private_View_Id is
   begin
      for Index in 1 .. Natural (Model.Views.Length) loop
         if Model.Views (Index).Full_Type = Full_Type then
            return Model.Views (Index).Id;
         end if;
      end loop;

      return No_Private_View;
   end Private_View_For_Full;

   function Private_View_Node
     (Model : Private_View_Model;
      Id    : Private_View_Id) return Private_View_Info is
   begin
      if Id = No_Private_View then
         return (others => <>);
      end if;

      for Index in 1 .. Natural (Model.Views.Length) loop
         if Model.Views (Index).Id = Id then
            return Model.Views (Index);
         end if;
      end loop;

      return (others => <>);
   end Private_View_Node;

   function View_Status_At_Line
     (Model        : Private_View_Model;
      Regions      : Editor.Ada_Declarative_Regions.Region_Model;
      Partial_Type : Editor.Ada_Type_Graph.Type_Id;
      Context      : Editor.Ada_Declarative_Regions.Region_Id;
      Source_Line  : Positive) return Private_View_Context_Status is
      Id : constant Private_View_Id := Private_View_For_Partial (Model, Partial_Type);
      View : constant Private_View_Info := Private_View_Node (Model, Id);
   begin
      if Id = No_Private_View then
         return Private_View_Context_Unknown;
      end if;

      if View.Status = Private_View_Full_View_Unresolved then
         return Private_View_Context_No_Full_View;
      end if;

      if Context = Editor.Ada_Declarative_Regions.No_Region then
         return Private_View_Context_Unknown;
      end if;

      if View.Package_Body_Region /= Editor.Ada_Declarative_Regions.No_Region
        and then Is_Ancestor_Or_Self (Regions, View.Package_Body_Region, Context)
      then
         return Private_View_Context_Full_View;
      end if;

      if Is_Ancestor_Or_Self (Regions, View.Package_Spec_Region, Context)
        and then Source_Line >= View.Private_Part_Line
      then
         return Private_View_Context_Full_View;
      end if;

      return Private_View_Context_Partial_Only;
   end View_Status_At_Line;

   function Full_View_Visible_At_Line
     (Model        : Private_View_Model;
      Regions      : Editor.Ada_Declarative_Regions.Region_Model;
      Partial_Type : Editor.Ada_Type_Graph.Type_Id;
      Context      : Editor.Ada_Declarative_Regions.Region_Id;
      Source_Line  : Positive) return Boolean is
   begin
      return View_Status_At_Line (Model, Regions, Partial_Type, Context, Source_Line) =
        Private_View_Context_Full_View;
   end Full_View_Visible_At_Line;

   function Effective_Type_At_Line
     (Model       : Private_View_Model;
      Regions     : Editor.Ada_Declarative_Regions.Region_Model;
      Type_Node   : Editor.Ada_Type_Graph.Type_Id;
      Context     : Editor.Ada_Declarative_Regions.Region_Id;
      Source_Line : Positive) return Editor.Ada_Type_Graph.Type_Id is
      Partial_Id : constant Private_View_Id := Private_View_For_Partial (Model, Type_Node);
      Full_Id    : constant Private_View_Id := Private_View_For_Full (Model, Type_Node);
   begin
      if Partial_Id /= No_Private_View then
         declare
            View : constant Private_View_Info := Private_View_Node (Model, Partial_Id);
         begin
            if Full_View_Visible_At_Line (Model, Regions, View.Partial_Type, Context, Source_Line)
              and then View.Full_Type /= Editor.Ada_Type_Graph.No_Type
            then
               return View.Full_Type;
            else
               return View.Partial_Type;
            end if;
         end;
      elsif Full_Id /= No_Private_View then
         declare
            View : constant Private_View_Info := Private_View_Node (Model, Full_Id);
         begin
            if Full_View_Visible_At_Line (Model, Regions, View.Partial_Type, Context, Source_Line) then
               return View.Full_Type;
            else
               return View.Partial_Type;
            end if;
         end;
      else
         return Type_Node;
      end if;
   end Effective_Type_At_Line;

   function Fingerprint (Model : Private_View_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Private_View_Visibility;
