with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Declaration_Parser.Declaration_Projection_Helpers;
with Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers;

package body Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Declaration_Collection is

   procedure Run
     (Phase   : in out Context;
      Analysis : in out Editor.Ada_Language_Model.Analysis_Result;
      Tree     : Editor.Ada_Syntax_Tree.Tree_Type)
   is
      use Editor.Ada_Language_Model;
      use Editor.Ada_Syntax_Tree;

      function First_Child_Label
        (Parent : Node_Id;
         Kind   : Node_Kind) return String
      is
      begin
         return Editor.Ada_Declaration_Parser.Declaration_Projection_Helpers
           .First_Child_Label (Tree, Parent, Kind);
      end First_Child_Label;

      function Ancestor_Symbol (Id : Node_Id) return Symbol_Id is
         P : Node_Id;
      begin
         if Id = No_Node then
            return No_Symbol;
         end if;

         P := Node (Tree, Id).Parent;
         while P /= No_Node loop
            if Natural (P) >= Natural (Phase.Node_Symbols'First)
              and then Natural (P) <= Natural (Phase.Node_Symbols'Last)
              and then Phase.Node_Symbols (Positive (P)) /= No_Symbol
            then
               return Phase.Node_Symbols (Positive (P));
            end if;
            P := Node (Tree, P).Parent;
         end loop;
         return No_Symbol;
      end Ancestor_Symbol;

      function Is_Access_Subprogram_Profile_Projection
        (Kind   : Symbol_Kind;
         Parent : Symbol_Id) return Boolean
      is
      begin
         if Kind /= Symbol_Discriminant
           or else Parent = No_Symbol
           or else Natural (Parent) > Symbol_Count (Analysis)
         then
            return False;
         end if;

         declare
            Parent_Info : constant Symbol_Info :=
              Symbol_At (Analysis, Positive (Parent));
         begin
            return Parent_Info.Flags.Has_Access_Subprogram_Metadata;
         end;
      end Is_Access_Subprogram_Profile_Projection;
   begin
      for I in 1 .. Node_Count (Tree) loop
         declare
            N : constant Node_Info := Node_At (Tree, I);
         begin
            if Editor.Ada_Declaration_Parser.Declaration_Projection_Helpers
              .Is_Declaration_Node (N.Kind)
            then
               declare
                  Raw_Name : constant String :=
                    First_Child_Label (N.Id, Node_Declaration_Name);
                  Name : constant String :=
                    Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers
                      .Clean_Projected_Declaration_Name (Raw_Name);
                  Kind : constant Symbol_Kind :=
                    Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers
                      .Syntax_Node_Symbol_Kind (Tree, N);
                  Parent : constant Symbol_Id := Ancestor_Symbol (N.Id);
                  Flags : constant Declaration_Flags :=
                    Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers
                      .Syntax_Node_Flags (Tree, N);
                  Target : constant String :=
                    First_Child_Label (N.Id, Node_Declaration_Target);
                  Profile : constant String :=
                    First_Child_Label (N.Id, Node_Declaration_Profile);
                  Id : Symbol_Id :=
                    Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers
                      .Find_Existing
                        (Analysis, Name, Kind, N.Source_Span.Start_Line);
               begin
                  if Name /= ""
                    and then not Is_Access_Subprogram_Profile_Projection
                      (Kind, Parent)
                  then
                     if Id = No_Symbol then
                        Id := Add_Symbol
                          (Analysis,
                           Name               => Name,
                           Kind               => Kind,
                           Source_Span        =>
                             Editor.Ada_Declaration_Parser.Declaration_Projection_Helpers
                               .To_Model_Range (N.Source_Span),
                           Declaration_Column => N.Source_Span.Start_Column,
                           Enclosing_Scope    => Scope_Id (Parent),
                           Parent_Symbol      => Parent,
                           Depth              => N.Depth,
                           Profile_Summary    => Profile,
                           Flags              => Flags,
                           Target_Name        => Target);
                     else
                        Merge_Symbol_Flags (Analysis, Id, Flags);
                        if Target /= "" then
                           declare
                              Existing_Target : constant String :=
                                To_String
                                  (Symbol_At
                                     (Analysis, Positive (Id)).Target_Name);
                           begin
                              if Existing_Target = "" then
                                 Set_Symbol_Target (Analysis, Id, Target);
                              end if;
                           end;
                        end if;
                        if Profile /= "" then
                           declare
                              Existing_Profile : constant String :=
                                To_String
                                  (Symbol_At
                                     (Analysis, Positive (Id)).Profile_Summary);
                           begin
                              if Existing_Profile = "" then
                                 Set_Symbol_Profile (Analysis, Id, Profile);
                              end if;
                           end;
                        end if;
                        declare
                           Existing : constant Symbol_Info :=
                             Symbol_At (Analysis, Positive (Id));
                           Merged_Kind : constant Symbol_Kind :=
                             Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers
                               .Preferred_Merged_Kind (Existing.Kind, Kind);
                        begin
                           if Merged_Kind /= Existing.Kind then
                              Set_Symbol_Kind (Analysis, Id, Merged_Kind);
                           end if;
                        end;
                     end if;
                     if Natural (N.Id) >= Natural (Phase.Node_Symbols'First)
                       and then Natural (N.Id) <= Natural (Phase.Node_Symbols'Last)
                     then
                        Phase.Node_Symbols (Positive (N.Id)) := Id;
                        Phase.Declaration_Count :=
                          Phase.Declaration_Count + 1;
                     end if;
                  end if;
               end;
            end if;
         end;
      end loop;
      Phase.Completed := True;
   end Run;

   function Is_Complete (Phase : Context) return Boolean is
   begin
      return Phase.Completed;
   end Is_Complete;

end Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Declaration_Collection;
