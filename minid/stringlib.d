/******************************************************************************
License:
Copyright (c) 2008 Jarrett Billingsley

This software is provided 'as-is', without any express or implied warranty.
In no event will the authors be held liable for any damages arising from the
use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it freely,
subject to the following restrictions:

    1. The origin of this software must not be misrepresented; you must not
	claim that you wrote the original software. If you use this software in a
	product, an acknowledgment in the product documentation would be
	appreciated but is not required.

    2. Altered source versions must be plainly marked as such, and must not
	be misrepresented as being the original software.

    3. This notice may not be removed or altered from any source distribution.
******************************************************************************/

module minid.stringlib;

import Float = tango.text.convert.Float;
import Integer = tango.text.convert.Integer;
import tango.core.Array;
import tango.text.Util;
import Uni = tango.text.Unicode;

import minid.ex;
import minid.interpreter;
import minid.types;
import minid.utils;

struct StringLib
{
static:
	public void init(MDThread* t)
	{
		pushGlobal(t, "modules");
		field(t, -1, "customLoaders");

		newFunction(t, function uword(MDThread* t, uword numParams)
		{
			newFunction(t, &join, "join"); newGlobal(t, "join");

			newNamespace(t, "string");
					newFunction(t, &iterator,        "iterator");
					newFunction(t, &iteratorReverse, "iteratorReverse");
				newFunction(t, &opApply,     "opApply", 2);  fielda(t, -2, "opApply");

				newFunction(t, &toInt,       "toInt");       fielda(t, -2, "toInt");
				newFunction(t, &toFloat,     "toFloat");     fielda(t, -2, "toFloat");
				newFunction(t, &compare,     "compare");     fielda(t, -2, "compare");
				newFunction(t, &icompare,    "icompare");    fielda(t, -2, "icompare");
				newFunction(t, &find,        "find");        fielda(t, -2, "find");
// 				newFunction(t, &ifind,       "ifind");       fielda(t, -2, "ifind");
				newFunction(t, &rfind,       "rfind");       fielda(t, -2, "rfind");
// 				newFunction(t, &irfind,      "irfind");      fielda(t, -2, "irfind");
				newFunction(t, &toLower,     "toLower");     fielda(t, -2, "toLower");
				newFunction(t, &toUpper,     "toUpper");     fielda(t, -2, "toUpper");
				newFunction(t, &repeat,      "repeat");      fielda(t, -2, "repeat");
				newFunction(t, &reverse,     "reverse");     fielda(t, -2, "reverse");
				newFunction(t, &split,       "split");       fielda(t, -2, "split");
				newFunction(t, &splitLines,  "splitLines");  fielda(t, -2, "splitLines");
				newFunction(t, &strip,       "strip");       fielda(t, -2, "strip");
				newFunction(t, &lstrip,      "lstrip");      fielda(t, -2, "lstrip");
				newFunction(t, &rstrip,      "rstrip");      fielda(t, -2, "rstrip");
				newFunction(t, &replace,     "replace");     fielda(t, -2, "replace");
				newFunction(t, &startsWith,  "startsWith");  fielda(t, -2, "startsWith");
				newFunction(t, &endsWith,    "endsWith");    fielda(t, -2, "endsWith");
// 				newFunction(t, &istartsWith, "istartsWith"); fielda(t, -2, "istartsWith");
// 				newFunction(t, &iendsWith,   "iendsWith");   fielda(t, -2, "iendsWith");
			setTypeMT(t, MDValue.Type.String);

			return 0;
		}, "string");
		
		fielda(t, -2, "string");
		pop(t);

		importModule(t, "string");
	}

	uword join(MDThread* t, uword numParams)
	{
		checkParam(t, 1, MDValue.Type.Array);
		checkStringParam(t, 2);
		auto data = getArray(t, 1).slice;

		if(data.length == 0)
		{
			pushString(t, "");
			return 1;
		}

		auto buf = StrBuffer(t);
		
		idxi(t, 1, 0);
		
		if(!isString(t, -1))
			throwException(t, "Array element 0 is not a string");
			
		buf.addTop();

		foreach(i, ref val; data[1 .. $])
		{
			if(val.type != MDValue.Type.String)
				throwException(t, "Array element {} is not a string", i + 1);

			dup(t, 2);
			buf.addTop();
			pushStringObj(t, val.mString);
			buf.addTop();
		}

		buf.finish();
		return 1;
	}

	uword toInt(MDThread* t, uword numParams)
	{
		auto src = checkStringParam(t, 0);

		int base = 10;

		if(numParams > 0)
			base = cast(int)getInt(t, 1);

		pushInt(t, safeCode(t, Integer.toInt(src, base)));
		return 1;
	}

	uword toFloat(MDThread* t, uword numParams)
	{
		pushFloat(t, safeCode(t, Float.toFloat(checkStringParam(t, 0))));
		return 1;
	}

	uword compare(MDThread* t, uword numParams)
	{
		pushInt(t, dcmp(checkStringParam(t, 0), checkStringParam(t, 1)));
		return 1;
	}

	uword icompare(MDThread* t, uword numParams)
	{
		pushInt(t, idcmp(checkStringParam(t, 0), checkStringParam(t, 1)));
		return 1;
	}

	uword find(MDThread* t, uword numParams)
	{
		auto src = checkStringParam(t, 0);

		if(isString(t, 1))
			pushInt(t, src.locatePattern(getString(t, 1)));
		else if(isChar(t, 1))
			pushInt(t, src.locate(getChar(t, 1)));
		else
		{
			pushTypeString(t, 1);
			throwException(t, "Parameter must be 'string' or 'char', not '{}'", getString(t, -1));
		}

		return 1;
	}

// 	uword ifind(MDThread* t, uword numParams)
// 	{
// 		dchar[32] buf1, buf2;
// 		dchar[] src = Uni.toFold(s.getContext!(MDString).mData, buf1);
// 		uword result;
// 
// 		if(s.isParam!("string")(0))
// 			result = src.locatePattern(Uni.toFold(s.getParam!(MDString)(0).mData, buf2));
// 		else if(s.isParam!("char")(0))
// 			result = src.locate(Uni.toFold([s.getParam!(dchar)(0)], buf2)[0]);
// 		else
// 			s.throwRuntimeException("Second parameter must be string or int");
// 			
// 		s.push(result);
// 
// 		return 1;
// 	}

	uword rfind(MDThread* t, uword numParams)
	{
		auto src = checkStringParam(t, 0);

		if(isString(t, 1))
			pushInt(t, src.locatePatternPrior(getString(t, 1)));
		else if(isChar(t, 1))
			pushInt(t, src.locatePrior(getChar(t, 1)));
		else
		{
			pushTypeString(t, 1);
			throwException(t, "Parameter must be 'string' or 'char', not '{}'", getString(t, -1));
		}

		return 1;
	}

// 	uword irfind(MDThread* t, uword numParams)
// 	{
// 		dchar[32] buf1, buf2;
// 		dchar[] src = Uni.toFold(s.getContext!(MDString).mData, buf1);
// 		uword result;
// 
// 		if(s.isParam!("string")(0))
// 			result = src.locatePatternPrior(Uni.toFold(s.getParam!(MDString)(0).mData, buf2));
// 		else if(s.isParam!("char")(0))
// 			result = src.locatePrior(Uni.toFold([s.getParam!(dchar)(0)], buf2)[0]);
// 		else
// 			s.throwRuntimeException("Second parameter must be string or int");
// 
// 		s.push(result);
// 
// 		return 1;
// 	}

	uword toLower(MDThread* t, uword numParams)
	{
		auto src = checkStringParam(t, 0);
		auto buf = StrBuffer(t);
		
		foreach(c; src)
		{
			dchar[1] inbuf = void;
			dchar[4] outbuf = void;
			
			inbuf[0] = c;
			buf.addString(Uni.toLower(inbuf[], outbuf[]));
		}

		buf.finish();
		return 1;
	}

	uword toUpper(MDThread* t, uword numParams)
	{
		auto src = checkStringParam(t, 0);
		auto buf = StrBuffer(t);
		
		foreach(c; src)
		{
			dchar[1] inbuf = void;
			dchar[4] outbuf = void;
			
			inbuf[0] = c;
			buf.addString(Uni.toUpper(inbuf[], outbuf[]));
		}

		buf.finish();
		return 1;
	}

	uword repeat(MDThread* t, uword numParams)
	{
		checkStringParam(t, 0);
		auto numTimes = checkIntParam(t, 1);

		if(numTimes < 0)
			throwException(t, "Invalid number of repetitions: {}", numTimes);

		auto buf = StrBuffer(t);

		for(mdint i = 0; i < numTimes; i++)
		{
			dup(t, 0);
			buf.addTop();
		}

		buf.finish();
		return 1;
	}

	uword reverse(MDThread* t, uword numParams)
	{
		auto src = checkStringParam(t, 0);

		if(src.length <= 1)
			dup(t, 0);
		else if(src.length <= 256)
		{
			dchar[256] buf = void;

			for(uword i = 0, j = src.length - 1; i < src.length; i++, j--)
				buf[i] = src[j];

			pushString(t, buf[0 .. src.length]);
		}
		else
		{
			auto tmp = t.vm.alloc.allocArray!(dchar)(src.length);
			scope(exit) t.vm.alloc.freeArray(tmp);

			for(uword i = 0, j = src.length - 1; i < src.length; i++, j--)
				tmp[i] = src[j];

			pushString(t, tmp);
		}

		return 1;
	}

	uword split(MDThread* t, uword numParams)
	{
		auto src = checkStringParam(t, 0);
		auto ret = newArray(t, 0);
		uword num = 0;

		if(numParams > 0)
		{
			foreach(piece; src.delimiters(checkStringParam(t, 1)))
			{
				pushString(t, piece);
				num++;
				
				if(num >= 50)
				{
					cateq(t, num);
					num = 0;
				}
			}
		}
		else
		{
			foreach(piece; src.delimiters(" \t\v\r\n\f\u2028\u2029"d))
			{
				if(piece.length > 0)
				{
					pushString(t, piece);
					num++;
					
					if(num >= 50)
					{
						cateq(t, num);
						num = 0;
					}
				}
			}
		}

		if(num > 0)
			cateq(t, num);

		return 1;
	}

	uword splitLines(MDThread* t, uword numParams)
	{
		auto src = checkStringParam(t, 0);
		auto ret = newArray(t, 0);
		uword num = 0;

		foreach(line; src.lines())
		{
			pushString(t, line);
			num++;
			
			if(num >= 50)
			{
				cateq(t, num);
				num = 0;
			}
		}

		if(num > 0)
			cateq(t, num);

		return 1;
	}

	uword strip(MDThread* t, uword numParams)
	{
		pushString(t, checkStringParam(t, 0).trim());
		return 1;
	}

	uword lstrip(MDThread* t, uword numParams)
	{
		pushString(t, checkStringParam(t, 0).triml());
		return 1;
	}

	uword rstrip(MDThread* t, uword numParams)
	{
		pushString(t, checkStringParam(t, 0).trimr());
		return 1;
	}

	uword replace(MDThread* t, uword numParams)
	{
		auto src = checkStringParam(t, 0);
		auto from = checkStringParam(t, 1);
		auto to = checkStringParam(t, 2);
		auto buf = StrBuffer(t);

		foreach(piece; src.patterns(from, to))
			buf.addString(piece);

		buf.finish();
		return 1;
	}

	uword iterator(MDThread* t, uword numParams)
	{
		checkParam(t, 0, MDValue.Type.String);
		auto index = checkIntParam(t, 1) + 1;

		if(index >= len(t, 0))
			return 0;

		pushInt(t, index);
		dup(t);
		idx(t, 0);

		return 2;
	}

	uword iteratorReverse(MDThread* t, uword numParams)
	{
		checkParam(t, 0, MDValue.Type.String);
		auto index = checkIntParam(t, 1) - 1;

		if(index < 0)
			return 0;

		pushInt(t, index);
		dup(t);
		idx(t, 0);

		return 2;
	}

	uword opApply(MDThread* t, uword numParams)
	{
		checkParam(t, 0, MDValue.Type.String);

		if(numParams > 0 && isString(t, 1) && getString(t, 1) == "reverse")
		{
			getUpval(t, 1);
			dup(t, 0);
			pushInt(t, len(t, 0));
		}
		else
		{
			getUpval(t, 0);
			dup(t, 0);
			pushInt(t, -1);
		}

		return 3;
	}

	uword startsWith(MDThread* t, uword numParams)
	{
		pushBool(t, .startsWith(checkStringParam(t, 0), checkStringParam(t, 1)));
		return 1;
	}

	uword endsWith(MDThread* t, uword numParams)
	{
		pushBool(t, .endsWith(checkStringParam(t, 0), checkStringParam(t, 1)));
		return 1;
	}

// 	uword istartsWith(MDThread* t, uword numParams)
// 	{
// 		dchar[32] buf1, buf2;
// 		auto string = Uni.toFold(s.getContext!(MDString).mData, buf1);
// 		auto pattern = Uni.toFold(s.getParam!(MDString)(0).mData, buf2);
// 
// 		if(pattern.length > string.length)
// 			s.push(false);
// 		else
// 			s.push(string[0 .. pattern.length] == pattern[]);
// 
// 		return 1;
// 	}
// 
// 	uword iendsWith(MDThread* t, uword numParams)
// 	{
// 		dchar[32] buf1, buf2;
// 		auto string = Uni.toFold(s.getContext!(MDString).mData, buf1);
// 		auto pattern = Uni.toFold(s.getParam!(MDString)(0).mData, buf2);
// 
// 		if(pattern.length > string.length)
// 			s.push(false);
// 		else
// 			s.push(string[$ - pattern.length .. $] == pattern[]);
// 
// 		return 1;
// 	}
}