/*
	This file is part of cpp-ethereum.

	cpp-ethereum is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	cpp-ethereum is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with cpp-ethereum.  If not, see <http://www.gnu.org/licenses/>.
*/
/** @file QBigInt.cpp
 * @author Yann yann@ethdev.com
 * @date 2015
 */

#include <boost/variant/multivisitors.hpp>
#include <boost/variant.hpp>
#include <libethcore/CommonJS.h>
#include "QBigInt.h"

using namespace dev;
using namespace dev::mix;
using namespace std;

void QBigInt::manageException() const
{
	try
	{
		throw;
	}
	catch (boost::exception const& _e)
	{
		cerr << boost::diagnostic_information(_e);
	}
	catch (exception const& _e)
	{
		cerr << _e.what();
	}
	catch (...)
	{
		cerr << boost::current_exception_diagnostic_information();
	}
}

QString QBigInt::value() const
{
	try
	{
		ostringstream s;
		s << m_internalValue;
		return QString::fromStdString(s.str());
	}
	catch (...)
	{
		manageException();
		return QString();
	}
}

QBigInt* QBigInt::subtract(QBigInt* const& _value) const
{
	try
	{
		if (!_value)
			return nullptr;
		BigIntVariant toSubtract = _value->internalValue();
		return new QBigInt(boost::apply_visitor(mix::subtract(), m_internalValue, toSubtract));
	}
	catch (...)
	{
		manageException();
		return nullptr;
	}
}

QBigInt* QBigInt::add(QBigInt* const& _value) const
{
	try
	{
		if (!_value)
			return nullptr;
		BigIntVariant toAdd = _value->internalValue();
		return new QBigInt(boost::apply_visitor(mix::add(), m_internalValue, toAdd));
	}
	catch (...)
	{
		manageException();
		return nullptr;
	}
}

QBigInt* QBigInt::multiply(QBigInt* const& _value) const
{
	try
	{
		if (!_value)
			return nullptr;
		BigIntVariant toMultiply = _value->internalValue();
		return new QBigInt(boost::apply_visitor(mix::multiply(), m_internalValue, toMultiply));
	}
	catch (...)
	{
		manageException();
		return nullptr;
	}
}

QBigInt* QBigInt::divide(QBigInt* const& _value) const
{
	try
	{
		if (!_value)
			return nullptr;
		BigIntVariant toDivide = _value->internalValue();
		return new QBigInt(boost::apply_visitor(mix::divide(), m_internalValue, toDivide));
	}
	catch (...)
	{
		manageException();
		return nullptr;
	}
}

QVariantMap QBigInt::checkAgainst(QString const& _type) const
{
	QVariantMap ret;
	try
	{
		QString type = _type;
		QString capacity = type.replace("uint", "").replace("int", "");
		if (capacity.isEmpty())
			capacity = "256";
		bigint range = 1;
		for (int k = 0; k < capacity.toInt() / 8; ++k)
			range = range * 256;
		bigint value = boost::get<bigint>(this->internalValue());
		ret.insert("valid", true);
		if (_type.startsWith("uint") && value > range - 1)
		{
			ret.insert("minValue", "0");
			ostringstream s;
			s << range - 1;
			ret.insert("maxValue", QString::fromStdString(s.str()));
			if (value > range)
				ret["valid"] = false;
		}
		else if (_type.startsWith("int"))
		{
			range = range / 2;
			ostringstream s;
			s << -range;
			ret.insert("minValue", QString::fromStdString(s.str()));
			s.str("");
			s.clear();
			s << range - 1;
			ret.insert("maxValue", QString::fromStdString(s.str()));
			if (-range > value || value > range - 1)
				ret["valid"] = false;
		}
	}
	catch (...)
	{
		manageException();
	}
	return ret;
}
