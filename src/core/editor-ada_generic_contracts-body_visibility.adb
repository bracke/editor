separate (Editor.Ada_Generic_Contracts)
package body Body_Visibility is

   function Direct_Body_Shadow
     (Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Body_Region : Editor.Ada_Declarative_Regions.Region_Id;
      Name : String) return Boolean
   is
      Lookup : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
        Editor.Ada_Direct_Visibility.Lookup_Direct
          (Visibility, Body_Region, Normalize (Name));
   begin
      return Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found
        or else Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Ambiguous;
   end Direct_Body_Shadow;

   function Body_Declaration_For_Generic
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Name       : String) return Editor.Ada_Direct_Visibility.Declaration_Info
   is
      N : constant String := Normalize (Name);
   begin
      for Index in 1 .. Editor.Ada_Direct_Visibility.Declaration_Count (Visibility) loop
         declare
            Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
              Editor.Ada_Direct_Visibility.Declaration_At (Visibility, Index);
            Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node (Tree, Decl.Node);
         begin
            if To_String (Decl.Normalized) = N
              and then (Node.Kind = Editor.Ada_Syntax_Tree.Node_Package_Body
                        or else Node.Kind = Editor.Ada_Syntax_Tree.Node_Subprogram_Body)
            then
               return Decl;
            end if;
         end;
      end loop;
      return Editor.Ada_Direct_Visibility.Declaration
        (Visibility, Editor.Ada_Direct_Visibility.No_Declaration);
   end Body_Declaration_For_Generic;

   function Body_Node_For_Generic
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Name : String) return Editor.Ada_Syntax_Tree.Node_Id
   is
      N : constant String := Normalize (Name);

      function Body_Name (Label : String) return String is
         Lower : constant String := Normalize (Label);
         Prefix : constant String := "package body ";
         Subp_Body : constant String := " body ";
         Start : Natural := 0;
         Last  : Natural;
      begin
         if Ada.Strings.Fixed.Index (Lower, Prefix) = Lower'First then
            Start := Lower'First + Prefix'Length;
         else
            declare
               Pos : constant Natural := Ada.Strings.Fixed.Index (Lower, Subp_Body);
            begin
               if Pos /= 0 then
                  Start := Pos + Subp_Body'Length;
               end if;
            end;
         end if;

         if Start = 0 or else Start > Lower'Last then
            return "";
         end if;

         Last := Ada.Strings.Fixed.Index (Lower (Start .. Lower'Last), " is");
         if Last /= 0 then
            Last := Last - 1;
         else
            Last := Lower'Last;
         end if;
         return Trim (Lower (Start .. Last));
      end Body_Name;
   begin
      for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
         declare
            Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
         begin
            if (Node.Kind = Editor.Ada_Syntax_Tree.Node_Package_Body
                or else Node.Kind = Editor.Ada_Syntax_Tree.Node_Subprogram_Body)
              and then Body_Name (To_String (Node.Label)) = N
            then
               return Node.Id;
            end if;
         end;
      end loop;
      return Editor.Ada_Syntax_Tree.No_Node;
   end Body_Node_For_Generic;

   function Contract_Declaration_For_Generic
     (Visibility    : Editor.Ada_Direct_Visibility.Visibility_Model;
      Formal_Region : Editor.Ada_Declarative_Regions.Region_Id)
      return Editor.Ada_Direct_Visibility.Declaration_Info
   is
   begin
      for Index in 1 .. Editor.Ada_Direct_Visibility.Declaration_Count (Visibility) loop
         declare
            Candidate : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
              Editor.Ada_Direct_Visibility.Declaration_At (Visibility, Index);
         begin
            if Candidate.Region = Formal_Region
              and then
                (Candidate.Kind = Editor.Ada_Direct_Visibility.Declaration_Package
                 or else Candidate.Kind = Editor.Ada_Direct_Visibility.Declaration_Subprogram)
            then
               return Candidate;
            end if;
         end;
      end loop;
      return Editor.Ada_Direct_Visibility.Declaration
        (Visibility, Editor.Ada_Direct_Visibility.No_Declaration);
   end Contract_Declaration_For_Generic;

   procedure Add_Body_Contract_Visibility
     (Model      : in out Generic_Contract_Model;
      Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Generic_Decl    : Editor.Ada_Direct_Visibility.Declaration_Info)
   is
      Id : constant Generic_Body_Contract_Visibility_Id :=
        Generic_Body_Contract_Visibility_Id
          (Natural (Model.Body_Contract_Visibility.Length) + 1);
      Generic_Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
        Editor.Ada_Syntax_Tree.Node (Tree, Generic_Decl.Node);
      Formal_Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.Region_For_Node (Regions, Generic_Decl.Node);
      Contract_Decl : Editor.Ada_Direct_Visibility.Declaration_Info :=
        Contract_Declaration_For_Generic (Visibility, Formal_Region);
      Body_Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
        Body_Declaration_For_Generic
          (Tree, Visibility,
           (if Contract_Decl.Id /= Editor.Ada_Direct_Visibility.No_Declaration
            then To_String (Contract_Decl.Normalized)
            else To_String (Generic_Decl.Normalized)));
      Body_Node : constant Editor.Ada_Syntax_Tree.Node_Id :=
        (if Body_Decl.Id /= Editor.Ada_Direct_Visibility.No_Declaration
         then Body_Decl.Node
         else Body_Node_For_Generic
           (Tree,
            (if Contract_Decl.Id /= Editor.Ada_Direct_Visibility.No_Declaration
             then To_String (Contract_Decl.Normalized)
             else To_String (Generic_Decl.Normalized))));
      Info : Generic_Body_Contract_Visibility_Info := Empty_Body_Contract_Visibility;
   begin
      Info.Id := Id;
      Info.Generic_Declaration := Generic_Decl.Id;
      Info.Generic_Node := Generic_Decl.Node;
      Info.Generic_Formal_Region := Formal_Region;
      if Contract_Decl.Id /= Editor.Ada_Direct_Visibility.No_Declaration then
         Info.Name := Contract_Decl.Name;
         Info.Normalized_Name := Contract_Decl.Normalized;
      else
         Info.Name := Generic_Decl.Name;
         Info.Normalized_Name := Generic_Decl.Normalized;
      end if;
      Info.Start_Line := Generic_Decl.Start_Line;
      Info.End_Line := Generic_Decl.End_Line;

      if Formal_Region = Editor.Ada_Declarative_Regions.No_Region then
         Info.Status := Generic_Body_Contract_No_Formal_Region;
      else
         for Formal_Info of Model.Formals loop
            if Formal_Info.Region = Formal_Region then
               Info.Formal_Count := Info.Formal_Count + 1;
            end if;
         end loop;

         if Body_Node = Editor.Ada_Syntax_Tree.No_Node then
            Info.Status := Generic_Body_Contract_Body_Not_Found;
         else
            Info.Body_Declaration := Body_Decl.Id;
            Info.Body_Node := Body_Node;
            Info.Body_Region := Editor.Ada_Declarative_Regions.Region_For_Node
              (Regions, Body_Node);
            Info.End_Line := Editor.Ada_Syntax_Tree.Node (Tree, Body_Node).Source_Span.End_Line;
            for Formal_Info of Model.Formals loop
               if Formal_Info.Region = Formal_Region then
                  if Direct_Body_Shadow
                    (Visibility, Info.Body_Region,
                     To_String (Formal_Info.Normalized_Name))
                  then
                     Info.Shadowed_Formals := Info.Shadowed_Formals + 1;
                     Info.Shadowed_Formal_Names := Append_Normalized_Name
                       (Info.Shadowed_Formal_Names,
                        To_String (Formal_Info.Normalized_Name));
                  else
                     Info.Visible_Formals := Info.Visible_Formals + 1;
                  end if;
               end if;
            end loop;
            Info.Status := Generic_Body_Contract_Visible;
         end if;
      end if;

      Info.Fingerprint :=
        (Natural (Id) * 1000003
         + Natural (Info.Generic_Declaration) * 1009
         + Natural (Info.Generic_Formal_Region) * 503
         + Natural (Info.Body_Declaration) * 97
         + Natural (Info.Body_Region) * 89
         + Generic_Body_Contract_Visibility_Status'Pos (Info.Status) * 43
         + Info.Formal_Count * 37
         + Info.Visible_Formals * 31
         + Info.Shadowed_Formals * 29
         + Hash_Text (To_String (Info.Shadowed_Formal_Names))
         + Hash_Text (To_String (Info.Normalized_Name))
         + Hash_Text (To_String (Generic_Node.Label))) mod Natural'Last;
      Model.Body_Contract_Visibility.Append (Info);
      Mix (Model, Info.Fingerprint);
   end Add_Body_Contract_Visibility;

   procedure Add_Body_Contract_Visibility_All
     (Model      : in out Generic_Contract_Model;
      Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model)
   is
   begin
      for Index in 1 .. Editor.Ada_Direct_Visibility.Declaration_Count (Visibility) loop
         declare
            Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
              Editor.Ada_Direct_Visibility.Declaration_At (Visibility, Index);
         begin
            if Decl.Kind = Editor.Ada_Direct_Visibility.Declaration_Generic then
               Add_Body_Contract_Visibility (Model, Tree, Regions, Visibility, Decl);
            end if;
         end;
      end loop;
   end Add_Body_Contract_Visibility_All;



end Body_Visibility;
