separate (Editor.Ada_Declaration_Parser.Executable_Binding_Scanner.Text_Scan)
package body Binding_Publication is

      function Resolve_Local_Target
        (Name : String;
         Line : Positive;
         Column : Positive) return Symbol_Id
      is
         Normalized : constant String := Normalize_Name (Name);
         Owner      : constant Symbol_Id := Scope_For_Position (Analysis, Line, Column);
         Owner_Scope : constant Scope_Id := Scope_Id (Natural (Owner));
      begin
         for I in reverse 1 .. Symbol_Count (Analysis) loop
            declare
               S : constant Symbol_Info := Symbol_At (Analysis, I);
            begin
               if To_String (S.Normalized_Name) = Normalized
                 and then S.Declaration_Line <= Line
                 and then (S.Enclosing_Scope = Owner_Scope
                           or else S.Enclosing_Scope = Root_Scope
                           or else S.Parent_Symbol = Owner)
               then
                  return S.Id;
               end if;
            end;
         end loop;
         return No_Symbol;
      end Resolve_Local_Target;


      procedure Add_Binding
        (Kind : Executable_Binding_Kind;
         Name : String;
         Expr : String;
         Line : Positive;
         Col  : Positive)
      is
         Clean : constant String := Trim (Name);
         Target : constant Symbol_Id := Resolve_Local_Target (Last_Selected_Part (Clean), Line, Col);
         Scope_Owner : constant Symbol_Id := Scope_For_Position (Analysis, Line, Col);
      begin
         if Clean'Length = 0 then
            return;
         end if;

         Add_Executable_Binding
           (Analysis        => Analysis,
            Kind            => Kind,
            Name            => Clean,
            Expression_Text => Expr,
            Scope           => Scope_Id (Natural (Scope_Owner)),
            Target_Symbol   => Target,
            Source_Span           => (Start_Line   => Line,
                                Start_Column => Positive'Max (1, Col),
                                End_Line     => Line,
                                End_Column   => Positive'Max (1, Col + Clean'Length - 1)));
      end Add_Binding;


      function Symbol_Kind_For_Target (Id : Symbol_Id) return Symbol_Kind is
      begin
         if Id = No_Symbol
           or else Natural (Id) = 0
           or else Natural (Id) > Symbol_Count (Analysis)
         then
            return Symbol_Unknown;
         end if;

         return Symbol_At (Analysis, Positive (Id)).Kind;
      end Symbol_Kind_For_Target;

      function Is_Indexable_Target
        (Name : String;
         Line : Positive;
         Col  : Positive) return Boolean
      is
         Id : constant Symbol_Id := Resolve_Local_Target (Last_Selected_Part (Name), Line, Col);
         K  : constant Symbol_Kind := Symbol_Kind_For_Target (Id);
      begin
         return K = Symbol_Object
           or else K = Symbol_Constant
           or else K = Symbol_Discriminant
           or else K = Symbol_Record_Component
           or else K = Symbol_Generic_Formal_Object;
      end Is_Indexable_Target;

      function Is_Type_Conversion_Target
        (Name : String;
         Line : Positive;
         Col  : Positive) return Boolean
      is
         Id : constant Symbol_Id := Resolve_Local_Target (Last_Selected_Part (Name), Line, Col);
         K  : constant Symbol_Kind := Symbol_Kind_For_Target (Id);
      begin
         return K = Symbol_Type
           or else K = Symbol_Subtype
           or else K = Symbol_Record_Type
           or else K = Symbol_Generic_Formal_Type;
      end Is_Type_Conversion_Target;

      function Is_Entry_Family_Target
        (Name : String;
         Line : Positive;
         Col  : Positive) return Boolean
      is
         Id : constant Symbol_Id := Resolve_Local_Target (Last_Selected_Part (Name), Line, Col);
         K  : constant Symbol_Kind := Symbol_Kind_For_Target (Id);
         Leaf : constant String := Normalize_Name (Last_Selected_Part (Name));
      begin
         --  an entry-family call has the same surface shape as an
         --  indexed object name: Entry_Name (Index).  When the prefix resolves
         --  to a retained entry declaration, preserve the parenthesized index
         --  as tasking metadata instead of array-index metadata.
         if K = Symbol_Entry then
            return True;
         end if;

         for I in reverse 1 .. Symbol_Count (Analysis) loop
            declare
               S : constant Symbol_Info := Symbol_At (Analysis, I);
            begin
               if S.Kind = Symbol_Entry
                 and then To_String (S.Normalized_Name) = Leaf
                 and then S.Declaration_Line <= Line
               then
                  return True;
               end if;
            end;
         end loop;

         return False;
      end Is_Entry_Family_Target;


end Binding_Publication;
