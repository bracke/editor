with Editor.Syntax;

package Editor.Syntax_State is

   --  Per-line lexical state.  A cache stores the state at each line start and
   --  relexes forward only until the outgoing state stabilizes.
   subtype Line_Start_State is Editor.Syntax.Lexical_State;

   function Is_Stateful (State : Line_Start_State) return Boolean;

end Editor.Syntax_State;
