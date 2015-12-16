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

QString QBigInt::value() const
{
	try
	{
		std::ostringstream s;
		s << m_internalValue;
		return QString::fromStdString(s.str());
	}
	catch (boost::exception const& _e)
	{
		std::cerr << boost::diagnostic_information(_e);
		return QString();
	}
	catch (std::exception const& _e)
	{
		std::cerr << _e.what();
		return QString();
	}
	catch (...)
	{
		std::cerr << boost::current_exception_diagnostic_information();
		return QString();
	}
}

QBigInt* QBigInt::subtract(QBigInt* const& _value) const
{
	try
	{
		BigIntVariant toSubtract = _value->internalValue();
		return new QBigInt(boost::apply_visitor(mix::subtract(), m_internalValue, toSubtract));
	}
	catch (boost::exception const& _e)
	{
		std::cerr << boost::diagnostic_information(_e);
		return nullptr;
	}
	catch (std::exception const& _e)
	{
		std::cerr << _e.what();
		return nullptr;
	}
	catch (...)
	{
		std::cerr << boost::current_exception_diagnostic_information();
		return nullptr;
	}
}

QBigInt* QBigInt::add(QBigInt* const& _value) const
{
	try
	{
		BigIntVariant toAdd = _value->internalValue();
		return new QBigInt(boost::apply_visitor(mix::add(), m_internalValue, toAdd));
	}
	catch (boost::exception const& _e)
	{
		std::cerr << boost::diagnostic_information(_e);
		return nullptr;
	}
	catch (std::exception const& _e)
	{
		std::cerr << _e.what();
		return nullptr;
	}
	catch (...)
	{
		std::cerr << boost::current_exception_diagnostic_information();
		return nullptr;
	}
}

QBigInt* QBigInt::multiply(QBigInt* const& _value) const
{
	try
	{
		BigIntVariant toMultiply = _value->internalValue();
		return new QBigInt(boost::apply_visitor(mix::multiply(), m_internalValue, toMultiply));
	}
	catch (boost::exception const& _e)
	{
		std::cerr << boost::diagnostic_information(_e);
		return nullptr;
	}
	catch (std::exception const& _e)
	{
		std::cerr << _e.what();
		return nullptr;
	}
	catch (...)
	{
		std::cerr << boost::current_exception_diagnostic_information();
		return nullptr;
	}
}

QBigInt* QBigInt::divide(QBigInt* const& _value) const
{
	try
	{
		BigIntVariant toDivide = _value->internalValue();
		return new QBigInt(boost::apply_visitor(mix::divide(), m_internalValue, toDivide));
	}
	catch (boost::exception const& _e)
	{
		std::cerr << boost::diagnostic_information(_e);
		return nullptr;
	}
	catch (std::exception const& _e)
	{
		std::cerr << _e.what();
		return nullptr;
	}
	catch (...)
	{
		std::cerr << boost::current_exception_diagnostic_information();
		return nullptr;
	}
}

QVariantMap QBigInt::checkAgainst(QString const& _type) const
{
	try
	{
		QVariantMap ret;
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
			std::ostringstream s;
			s << range - 1;
			ret.insert("maxValue", QString::fromStdString(s.str()));
			if (value > range)
				ret["valid"] = false;
		}
		else if (_type.startsWith("int"))
		{
			range = range / 2;
			std::ostringstream s;
			s << -range;
			ret.insert("minValue", QString::fromStdString(s.str()));
			s.str("");
			s.clear();
			s << range - 1;
			ret.insert("maxValue", QString::fromStdString(s.str()));
			if (-range > value || value > range - 1)
				ret["valid"] = false;
		}
		return ret;
	}
	catch (boost::exception const& _e)
	{
		std::cerr << boost::diagnostic_information(_e);
		return QVariantMap();
	}
	catch (std::exception const& _e)
	{
		std::cerr << _e.what();
		return QVariantMap();
	}
	catch (...)
	{
		std::cerr << boost::current_exception_diagnostic_information();
		return QVariantMap();
	}
}
